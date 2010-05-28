module RedisGraph
  module Node        
    def self.included(model)
      model.extend(Node::Descendants, Node::Properties, Node::ClassMethods)
      model.class_eval do
        include Validatable
      end
    end

    def initialize(props = {})
      @_saved = false
      self.key = props.delete(:key)      
      self.properties = props
    end

    # @api public
    def ==(other)
      other.is_a?(self.class) && self.key == other.key
    end

    # @api public
    def eql?(other)
      self == other
    end

    # @api public
    def equal?(other)
      object_id === other.object_id
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
      # Bail, if there's nothing to do anyways
      return true unless dirty?
      
      # Bail, if there's validation errors.
      return false unless valid?
      
      # We shouldn't save the Node if it has not yet been created but a Node with the same key already exists
      if !saved? && self.class.exists?(self.key)
        #raise NodeKeyAlreadyExistsError, "A #{self.class.to_s} Node with the key of '#{self.key}' already exists, if you wish to overwrite it first get the Node, update it, and then save."
        # @todo add error
        return false
      end
      
      # @todo I'm using MULTI as if it's a transaction, except it isn't, as if one command fails 
      # all commands follow it will execute (http://code.google.com/p/redis/wiki/MultiExecCommand). This
      # is currently an unresolved issue, mainly 'cause I don't know how yet...
      RedisGraph.connection.multi do
        # If the key has been changed then shift every property to the new key
        if saved? && @_key != self.key
          RedisGraph.connection.renamenx( self.class.redis_key(@_key), self.class.redis_key(self.key) )

          self.non_hash_raw_properties.each do |name, property|
            # Don't try and modify a key if it won't exist. It won't exist if the value of the key is nil
            # We need to make sure we are checking the value in the DB, though, not the possibly dirty value
            # in our Node.
            if property.saved?
              RedisGraph.connection.renamenx( self.class.redis_key(@_key, name), self.class.redis_key(self.key, name) )
            end
          end
        end

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

     end
      
      reset!
      true
    end

    # Reset dirty tracking, current key, and saved state.
    #
    # @api semi-public
    def reset!
      @_key = self.key
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
      self.class.redis_key(*segments.unshift(self.key))
    end
  end # module Node
end # module RedisGraph

