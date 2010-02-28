module RedisGraph
  module Nodes
    module Properties
      Node.append_extensions self

      extend DataMapper::Chainable

      def extended(model)
        puts "EXTENDED"
        model.instance_variable_set(:@properties, {})
        model.send(:include, InstanceMethods)
      end

      chainable do
        def inherited(model)
          model.instance_variable_set(:@properties, {})

          # Copy the parent class' properties into the sub class
          model_properties = model.properties
          @properties.each do |property|
            model_properties[property.name] ||= property
          end

          super
        end
      end
      
      module InstanceMethods
        def properties
         instance_variable_get(:@properties)
        end

        def properties=(props)
          # Look for keys in props that we don't recognise and raise exceptions for them
          unknown_keys = props.keys - properties.keys
          unless unknown_keys.empty?
            unknown_keys = unknown_keys.collect {|key| "'#{key}'" }.join(', ')
            raise NoMethodError, "undefined properties #{unknown_keys} for #{inspect}:#{self.class}"
          end

          props.each do |name, value|
            self.send("#{name}=".to_sym, value)
          end
          
          self
        end
      end # module InstanceMethods

      # Defines a Property on the Node
      #
      # @param [Symbol] name
      #   the name for which to call this property
      # @param [Type] type
      #   the type to define this property ass
      # @param [Hash(Symbol => String)] options
      #   a hash of available options
      #
      # @return [Property]
      #   the created Property
      #
      # @api public    
      def property(name, type, options = {})
        name = name.to_sym

        property = Property.new(self, name, type, options)
        properties[name.to_sym] << property

        # Add the property to the child classes only if the property was
        # added after the child classes' properties have been copied from
        # the parent
        descendants.each do |descendant|
          descendant.properties[name] ||= property
        end

        # create reader
        create_property_reader(property)
        
        # create writer
        create_property_writer(property)

        property
      end

      # Retrieves the list of all properties
      #
      # @return [Array]
      #   the list of properties
      #
      # @api public
      def properties
        @properties
      end
      
      private
      
      def create_property_reader(property)
        unless defined?(property.name)
          node.class_eval <<-EOS, __FILE__, __LINE__
          #{property.reader_visibility}
          def #{property.name.to_s}
            return #{instance_variable_name} if defined?(#{instance_variable_name})
            #{property.instance_variable_name} = properties[:#{property.name.to_s}].get(self)
          end
          EOS
        end

        boolean_reader_name = "#{property.name.to_s}?".to_sym
        if property.type == TrueClass && !defined?(boolean_reader_name)
          node.class_eval <<-EOS, __FILE__, __LINE__
          #{property.reader_visibility}
          alias #{boolean_reader_name}? #{property.name.to_s}
          EOS
        end
      end

      def create_property_writer(property)
        unless defined?("#{property.name.to_s}=".to_sym)
          node.class_eval <<-EOS, __FILE__, __LINE__
          #{property.writer_visibility}
          def #{property.name.to_s}=(value)
            #{property.instance_variable_name} = value
          end
          EOS
        end
      end
    end # module Properties
  end # module Nodes
end # module RedisGraph