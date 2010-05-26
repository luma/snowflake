module RedisGraph
  module Node        
    def self.included(model)
      model.extend(Node::Descendants, Node::Properties, Node::ClassMethods)
    end

    def initialize(props = {})
      self.id = props.delete(:id)      
      self.properties = props
    end

    #
    def save
      # Bail if there's nothing to do anyways
      return true unless dirty?
      
      if self.id.blank?
        raise MissingIdPropertyError, "An instance of #{self.class.to_s} could not be saved as it lacked an ID."
      end

#      puts "DIRTY: #{dirty_properties_names.inspect}"

      # @todo This is kind of hacky, right now
      # @todo Also, I'm using MULTI as if it's a transaction, except it isn't, as if one command fails all commands follow it will execute (http://code.google.com/p/redis/wiki/MultiExecCommand)
#      RedisGraph.connection.multi do
        # We need to get all get Properties that should be part of the main object hash and separate them out from the others
        # They get added into a single Redis Hash
=begin
        hash_properties = self.class.hash_properties.collect do |name| 
            property = read_raw_property(name)
            if property.dirty?
              [name, property.to_s]
            else
              nil
            end
        end.compact.flatten
=end        

        unless dirty_hash_properties.empty?
          puts "SAVING HASH: #{dirty_hash_properties.inspect}"
          RedisGraph.connection.hmset( *dirty_hash_properties.to_a.flatten.unshift(redis_key) )
        end

        # All other more complex properties (counters, lists, sets, etc) get serialised individually.
=begin
        self.class.non_hash_properties.each do |name|
          property = read_raw_property(name)

          if property.dirty?
            puts "SAVING CUSTOM #{name}"
            unless property == nil
              property.store!
            else
              RedisGraph.connection.del( redis_key(name) )
            end
          end
        end
=end

        self.dirty_non_hash_properties.each do |name, property|
          puts "SAVING CUSTOM #{name}"
          unless property == nil
            property.store!
          else
            RedisGraph.connection.del( redis_key(name) )
          end          
        end

#      end

      clean!

    end
    
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

