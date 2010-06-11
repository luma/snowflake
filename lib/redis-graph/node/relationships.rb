module RedisGraph
  module Node
    module Relationships
      def self.extended(model)
        model.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def relationships
        end
        
        def has_relationship?(name)
        end
        
        def raw_relationships
          self.class.relationships.keys.collect do |name|
            read_raw_relationship(name)
          end
        end
        
        # Reads the value of the Relationship called +name+.
        #
        # @param [#to_sym] name
        #     The name of the Relationship value to read
        #
        # @return [Any]
        def read_relationship(name)
          relationship = read_raw_relationship(name)

          if relationship == nil
            relationship = self.class.relationships[name.to_sym].get(self)
            instance_variable_set(Relationship.instance_variable_name(name), relationship)
          end

          relationship.enumerable?? relationship : relationship.to_edge
        end

        # Reads the raw Relationship object of the Relationship called +name+.
        #
        # @param [#to_sym] name
        #     The name of the Relationship value to read
        #
        # @return [Relationship]
        def read_raw_relationship(name)
          instance_variable_get(Relationship.instance_variable_name(name))
        end

        def write_relationship(name, value)
        end

        def write_raw_relationship(name, relationship)
          instance_variable_set(Relationship.instance_variable_name(name), relationship)
        end
      end  # module InstanceMethods


      def belongs_to(name)
        add_relationship(name, :BelongsTo, options)
      end

      def has(name, options = {})
        add_relationship(name, :Has, options)
      end

      # Retrieves the list of all relationships
      #
      # @return [Array]
      #   the list of relationships
      #
      # @api public
      def relationships
        @relationships ||= {}
      end
      
      private
      
      def add_relationship(name, type, options)
        relationships[name] = Relationship.new(name, type, options)

        create_relationship_reader(relationships[name])
        create_relationship_writer(relationships[name])
      end

      # @todo prevent these from being defined if they have already been defined somewhere else
      def create_relationship_reader(relationship)
        class_eval <<-EOS, __FILE__, __LINE__ + 1
        #{relationship.reader_visibility}
        def #{relationship.name.to_s}
          read_relationship(:#{relationship.name.to_s})
        end
        EOS
      end

      # @todo prevent these from being defined if they have already been defined somewhere else
      def create_relationship_writer(relationship)
        class_eval <<-EOS, __FILE__, __LINE__ + 1
        #{relationship.writer_visibility}
        def #{relationship.name.to_s}=(value)
          write_relationship(:#{relationship.name.to_s}, value)
        end
        EOS
      end
    end # module Relationships
  end # module Node
end # module RedisGraph