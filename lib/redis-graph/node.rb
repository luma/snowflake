module RedisGraph
  module Node        
    def self.included(model)
      model.extend(Node::Descendants, Node::Properties, Node::ClassMethods)
    end

    def initialize(props = {})
      @_saved = false
      self.id = props.delete(:id)      
      self.properties = props
    end
    
    # Indicates whether this Node has been saved yet.
    #
    # @return [Boolean]
    #   True if this Node has been saved, false otherwise.
    #
    # @api public
    def saved?
      @_saved == true
    end

    # Save the Node to the DB.
    #
    # @return [Boolean]
    #     True if the save was successful, false otherwise.
    #
    # @api public
    def save
      # Bail if there's nothing to do anyways
      return true unless dirty?
      
      if self.id.blank?
        raise MissingIdPropertyError, "An instance of #{self.class.to_s} could not be saved as it lacked an ID."
      end

      # @todo This is kind of hacky, right now
      # @todo Also, I'm using MULTI as if it's a transaction, except it isn't, as if one command fails all commands follow it will execute (http://code.google.com/p/redis/wiki/MultiExecCommand)
#      RedisGraph.connection.multi do
        # We need to get all get Properties that should be part of the main object hash and separate them out from the others
        # They get added into a single Redis Hash
        unless dirty_hash_properties.empty?
          RedisGraph.connection.hmset( *dirty_hash_properties.to_a.flatten.unshift(redis_key) )
        end

        # All other more complex properties (counters, lists, sets, etc) get serialised individually.
        self.dirty_non_hash_properties.each do |name, property|
          unless property == nil
            property.store!
          else
            RedisGraph.connection.del( redis_key(name) )
          end          
        end

#      end
      
      reset!

    end
    
    # Reset dirty tracking and saved state.
    #
    # @api semi-public
    def reset!
      @_saved = true
      clean!
    end
    
    # @api private
    def send_command(path_suffix, command, *args)
      unless path_suffix == nil
        RedisGraph.connection.send(command.to_sym, *args.unshift( redis_key(path_suffix.to_s) ) )
      else
        RedisGraph.connection.send(command.to_sym, *args.unshift( redis_key ) )
      end
    end

#    protected

    # @todo I'm not sure this should be public
    def redis_key(*segments)
      self.class.redis_key(*segments.unshift(self.id))
    end
  end # module Node
end # module RedisGraph

