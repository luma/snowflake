module Snowflake
  module Node
    module Properties
      def self.extended(model)
        model.send(:include, InstanceMethods)
      end

      module InstanceMethods
        # Retrieves all Node attributes.
        #
        # @return [Hash]
        #     The array of properties
        #
        # @api public
        def attributes
          property_names_to_property_hash( self.class.hash_properties | self.class.non_hash_properties )
        end

        # Mass-assign the Node's attributes.
        #
        # @param [Hash]
        #     The new Node properties.
        #
        # @return [Node]
        #     The Node.
        #
        # @api public
        def attributes=(props)
          props.each do |name, value|
            unless self.class.properties.include?(name.to_sym)
              raise NoMethodError, "Undefined property #{name.to_s} for #{inspect}:#{self.class}"
            end

            write_property(name, value)
          end
          
          self
        end
        
        # Retrieves only properties that are part of the main object Hash
        #
        # @return [Hash]
        #     The array of properties
        #
        # @api private
        def hash_properties
          property_names_to_property_hash(self.class.hash_properties)
        end

        # Retrieves only properties that are *not* part of the main object Hash
        #
        # @return [Hash]
        #     The array of properties
        #
        # @api private
        def non_hash_properties
          property_names_to_property_hash(self.class.non_hash_properties)
        end        

        # Retrieve the value of the key property for this Node
        #
        # @return [#to_s] The Id value
        #
        # @api public
        def key
          read_property(self.class.key)
        end

        # Assigns the value of the key property for this Node
        #
        # @param [#to_s] The key value
        #
        # @return [#to_s] The key value
        #
        # @api public
        def key=(new_key)
          write_property(self.class.key, new_key)
        end

        # Indicates whether any properties have been modified since the last save.
        #
        # @return [Boolean]
        #     True if changes have been made, false otherwise.
        #
        # @api public
        def dirty?
          #dirty_properties.empty?

          (self.class.hash_properties | self.class.non_hash_properties).each do |name|
            property = read_proxy_property(name)
            if property != nil && read_proxy_property(name).dirty?
              return true
            end
          end

          false
        end

        protected

        # Retrieves only the Properties that have been changed since the last save.
        #
        # @return [Array<Properties>]
        #     A Array containing any modified properties.
        #
        # @api private
        def dirty_properties
          property_names_to_raw_property_hash( self.class.hash_properties | self.class.non_hash_properties ) do |property|
            if property.dirty?
              [property.name, property]
            else
              nil
            end
          end
        end

        # Clear our dirty tracking
        #
        # @api private
        def clean!
          dirty_properties.each do |name, property|
            property.clean!
          end
        end

        # Reads the value of the Property called +name+.
        #
        # @param [#to_sym] name
        #     The name of the Property value to read
        #
        # @return [Any]
        def read_property(name)
          property = read_proxy_property(name)

          if property == nil
            property = self.class.properties[name.to_sym].to_property(self)
            instance_variable_set(Property.instance_variable_name(name), property)
          end

          property.primitive?? property.raw : property
        end

        # Reads the raw Property object of the Property called +name+.
        #
        # @param [#to_sym] name
        #     The name of the Property value to read
        #
        # @return [Property]
        def read_proxy_property(name)
          instance_variable_get(Property.instance_variable_name(name))
        end

        # Writes the value of the Property called +name+ with +value+.
        #
        # @param [#to_sym] name
        #     The name of the Property value to read
        #
        # @param [Any] value
        #     The value to assign to Property +name+
        #
        # @param [Boolean] make_dirty
        #     Indicates whether the method should be marked as dirty after writing it.
        #
        # @todo Handle Typecasting
        #
        # @return [Any]
        def write_property(name, value, make_dirty = true)
          property = read_proxy_property(name)
          
          # Don't instantiate the property object until we need it
          if property == nil
            property = self.class.properties[name.to_sym].to_property(self)
          end

          # @todo typecast value to ensure is the raw type for property
          property.raw = value
          
          # By default, modifications to a Property's raw value are dirty tracked, but
          # we can override that if the callee desires...
          unless make_dirty
            property.clean!
          end
          
          #instance_variable_set(Property.instance_variable_name(name), property)
          write_proxy_property(name, property)
        end
        
        # Assigns the Property Object of the Property called +name+ with +value+.
        #
        # @param [#to_sym] name
        #     The name of the Property value to read
        #
        # @param [Property] property
        #     The Property object to assign to Property +name+
        #
        # @todo Handle Typecasting
        #
        # @return [Any]
        def write_proxy_property(name, property)
          instance_variable_set(Property.instance_variable_name(name), property)
        end

        # Retrieves all Node properties. This always returns the Property objects, it does
        # no typecasting.
        #
        # @return [Hash]
        #     The array of properties
        #
        # @api private
        def property_proxies
          property_names_to_raw_property_hash( self.class.hash_properties | self.class.non_hash_properties )
        end
        
        # Retrieves only properties that are **Not** part of the main object Hash.
        #
        # This method differs from the non_hash_properties method as it always returns the raw 
        # Property object.
        #
        # @return [Hash]
        #     The array of properties
        #
        # @api private
        def non_hash_property_proxies
          property_names_to_raw_property_hash(self.class.non_hash_properties) do |property|
            [property.name, property]
          end
        end

        # Retrieves only properties that are:
        # 1. Dirty.
        # 2. Part of the main object Hash.
        #
        # This method differs from the hash_properties method as it always returns the raw 
        # Property object.
        #
        # @return [Hash]
        #     The array of properties
        #
        # @api private
        def dirty_hash_properties
          property_names_to_raw_property_hash(self.class.hash_properties) do |property|
            if property.dirty?
              [property.name, property]
            else
              nil
            end
          end
        end

        # Retrieves only properties that are:
        # 1. Dirty.
        # 2. **Not** part of the main object Hash.
        #
        # This method differs from the hash_properties method as it always returns the raw 
        # Property object.
        #
        # @return [Hash]
        #     The array of properties
        #
        # @api private
        def dirty_non_hash_properties
          property_names_to_raw_property_hash(self.class.non_hash_properties) do |property|
            if property.dirty?
              [property.name, property]
            else
              nil
            end
          end
        end

        private

        def property_names_to_property_hash(property_names)
          Hash[*property_names.collect do |name| 
               [name, read_property(name)] 
          end.flatten]
        end
        
        def property_names_to_raw_property_hash(property_names)
          Hash[*property_names.collect do |name|
            property = read_proxy_property(name)
            unless property == nil
              unless block_given?
                [name, property] 
              else
                yield( property )
              end
            else
              nil
            end
          end.compact.flatten]
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

        if properties.include?(name)
          raise PropertyNameInUseError, "A Property called '#{name.to_s}' has already been defined for #{self.inspect}."
        end
        
#        if reserved_propery_names.include?(name)
#          raise ArgumentError, "'#{name}' is a reserved property name, it cannot be used. The following are all reserved property names: #{reserved_propery_names.join(', ')}"
#        end

        # 'key' is a reserved property name, you can use it but you must set :key => true as well.
        if name == :key && ( !options.include?(:key) || options[:key] == false )
          raise ArgumentError, "You can't call a property 'key' unless you also set the :key option to true."
        end

        prototype = PropertyPrototype.new(self, name, type, options)

        # If this property is supposed to be the key then we take a note of it.
        if prototype.key?
          if @key.blank?
            self.key = name
          else
            raise InvalidPropertyError, "More than one property cannot be the Node key, #{self.key.to_s} is already the key for #{self.inspect}"
          end
        end

        if prototype.hash_property?
          hash_properties << name
        else
          non_hash_properties << name
        end
        
        properties[name] = prototype

        # Add the property to the child classes only if the property was
        # added after the child classes' properties have been copied from
        # the parent
        descendants.each do |descendant|
          descendant.properties[name] ||= prototype
        end

        # Create our accessors, we don't bother if the property is named key, there are already
        # accessors for key
        unless name == :key
          # create reader
          create_property_reader(prototype)
        
          # create writer
          create_property_writer(prototype)
        end

        prototype
      end
      
      # Retrieves the list of all properties
      #
      # @return [Array]
      #   the list of properties
      #
      # @api public
      def properties
        @properties ||= {}
      end
      
      # Retrieves only properties that are part of the main object Hash
      #
      # @return [Array]
      #     The array of properties
      #
      # @api private
      def hash_properties
        @hash_properties ||= Set.new
      end
      
      # Retrieves only properties that are *not* part of the main object Hash
      #
      # @return [Array]
      #     The array of properties
      #
      # @api private
      def non_hash_properties
        @non_hash_properties ||= Set.new
      end
      
      def key=(property_name)
        @key = property_name.to_sym
      end

      def key
        @key ||= begin
          # Auto-magically create a default key property
          begin
            property :key, ::Snowflake::Properties::Guid, :key => true
          rescue PropertyNameInUseError => e
            # What happens if there's is a Property called :key already? We get an exception that can be
            # a little obscure. We make it a little more obvious here and re-raise it.
            raise PropertyNameInUseError, "No key Property was defined on this Node, we tried to create one called 'key' for you but the property name 'key' was already in use. Please choose a property to be the Node key."
          end

          :key
        end
      end
     
      private
      
      # @todo prevent these from being defined if they have already been defined somewhere else
      # @todo typecast
      def create_property_reader(prototype)
#        unless defined?(prototype.name)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
          #{prototype.reader_visibility}
          def #{prototype.name.to_s}
            read_property(:#{prototype.name.to_s})
          end
          EOS
#        end

        if prototype.type.is_a?(::Snowflake::Properties::Boolean) #&& !defined?(boolean_reader_name)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
          #{prototype.reader_visibility}
          alias :#{prototype.name.to_s}? :#{prototype.name.to_s}
          EOS
        end
      end

      # @todo prevent these from being defined if they have already been defined somewhere else
      # @todo Handle Typecasting
      def create_property_writer(prototype)
#        unless defined?("#{prototype.name.to_s}=".to_sym)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
          #{prototype.writer_visibility}
          def #{prototype.name.to_s}=(value)
            write_property(:#{prototype.name.to_s}, value)
          end
          EOS
#        end
      end

    end # module properties
  end # module Node
end # module Snowflake