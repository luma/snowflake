module Snowflake
  module Element
    module Plugins
      module Attributes
        Model.add_extensions self

        def self.extended(model)
          model.send(:include, InstanceMethods)
        end

        module InstanceMethods
          # Retrieves all Node attributes that are dirty, those that have been modified.
          #
          # @return [Hash]
          #     The array of dirty attributes
          #
          # @api public
          def dirty_attributes
            @dirty_attributes ||= {}
          end

          # Retrieves all Node attributes.
          #
          # @return [Hash]
          #     The array of attributes
          #
          # @api public
          def attributes
            @attributes ||= {}
          end

          # Synonym of update_attributes.
          #
          # @param [Hash]
          #     The new Node attributes.
          #
          # @return [Node]
          #     The Node.
          #
          # @api public
          def attributes=(attrs)
            update_attributes(attrs)
          end

          # Mass-assign the Node's attributes. If dynamic attributes are enabled unknown
          # attributes will be automatically created.
          #
          # @param [Hash]
          #     The new Node attributes.
          #
          # @return [Node]
          #     The Node.
          #
          # @api public          
          def update_attributes(attrs)
            # If dynamic attributes are allowed then we'll just write all the attributes without checking
            # whether they have been explicitly defined. If dynamic attributes are not allowed then we'll 
            # need to raise an exception on any undeclared attributes.
            if self.class.allow_dynamic_attributes?
              attrs.each do |name, value|
                if dynamic_attribute?(name)
                  add_dynamic_attribute(name, value)
                else
                  write_attribute(name, value)
                end
              end
            else
              attrs.each do |name, value|
                if dynamic_attribute?(name)
                  raise NoMethodError, "Undefined attribute #{name.to_s} for #{inspect}:#{self.class}"
                end

                write_attribute(name, value)
              end
            end

            self
          end

          # Retrieve the value of the key attribute for this Node
          #
          # @return [#to_s] The Id value
          #
          # @api public
          def key
            read_attribute(self.class.key)
          end

          # Assigns the value of the key attribute for this Node
          #
          # @param [#to_s] The key value
          #
          # @return [#to_s] The key value
          #
          # @api public
          def key=(new_key)
            write_attribute(self.class.key, new_key)
          end

          # Indicates true if any attributes have been modified since the last save.
          #
          # @return [Boolean]
          #     True if changes have been made, false otherwise.
          #
          # @api public
          def dirty?
            !dirty_attributes.empty?
          end

          # Indicates false if any attributes have been modified since the last save.
          #
          # @return [Boolean]
          #     True if no changes have been made, false otherwise.
          #
          # @api public          
          def clean?
            dirty_attributes.empty?
          end

          # Adds a new dynamic attribute to the Element, you must call this method before
          # attempting to write a value to the new attribute.
          #
          # @param [Symbol, #to_sym] name
          #   The new attribute's name.
          # @param [String, #to_s, nil] value
          #   The initial value to set, defaults to nil.
          #
          # @return [Boolean]
          #   True if the dynamic attribute was created sucessfully, false otherwise.
          #
          # @api public
          def add_dynamic_attribute(name, value = nil)
            unless self.class.allow_dynamic_attributes?
              raise DynamicAttributeError, "Cannot add the '#{name}' attribute, dynamic attributes are disabled for #{self.class}"
            end

            # Don't create it if it's already been created
            if has_attribute?(name)
              raise ArgumentError, "A dynamic attribute called '#{name}' already exists and attributes cannot be redefined."
            end

            # Guard against creating dynamic attributes using the restricted attribute names. 
            if Attribute.restricted_name?(name.to_sym)
              raise ArgumentError, "'#{name}' is a restricted attribute name, it cannot be used. The following are all restricted attribute names: #{self.class.restricted_attribute_names.join(', ')}"
            end            

            # Create the dynamic attribute
            self.class.attribute(name, ::Snowflake::Attributes::Dynamic)

            write_attribute(name, value)

            true
          end

          def dynamic_attribute?(name)
            self.class.dynamic_attribute?(name)
          end

          protected

          # Clear our attribute dirty tracking
          #
          # @api private
          def clean!
            dirty_attributes = {}
          end

          # Reads the value of the Attribute called +name+.
          #
          # @param [#to_sym] name
          #     The name of the Attribute value to read
          #
          # @return [Any]
          #   +value+
          #
          # @api private
          def read_attribute(name)
            read_raw_attribute(name)
          end

          # Reads the raw value of the Attribute called +name+.
          #
          # @param [#to_sym] name
          #     The name of the Attribute value to read
          #
          # @return [Any]
          #   +value+
          #
          # @api private
          def read_raw_attribute(name)
            attributes[name.to_sym]
          end

          # Writes the value of the Attribute called +name+ with +value+.
          #
          # @param [#to_sym] name
          #     The name of the Attribute value to write to.
          #
          # @param [Any] value
          #     The value to assign to Attribute called +name+.
          #
          # @param [Boolean] make_dirty
          #     Indicates whether the method should be marked as dirty after writing it.
          #
          # @todo Handle Typecasting
          #
          # @return [Any]
          #   +value+
          #
          # @api private
          def write_attribute(name, value, make_dirty = true)
            if make_dirty
              dirty_attributes[name.to_sym] = read_attribute(name)
            end

            proxy = self.class.attributes[name.to_sym]
            write_raw_attribute(name, proxy.typecast(value))
          end

          # Assigns the raw value of the Attribute called +name+ with +value+.
          #
          # @param [#to_sym] name
          #     The name of the Property value to write +value+ to
          #
          # @param [Any] value
          #     The raw attribute value to assign to Attribute +name+
          #
          # @todo Handle Typecasting
          #
          # @return [Any]
          #   +value+
          #
          # @api private
          def write_raw_attribute(name, value)
            attributes[name.to_sym] = value
          end
        end # module InstanceMethods

        # Defines a Attribute on the Node
        #
        # @param [Symbol] name
        #   the name for which to call this attribute
        # @param [Type] type
        #   the type to define this attribute ass
        # @param [Hash(Symbol => String)] options
        #   a hash of available options
        #
        # @return [Attribute]
        #   the created Attribute
        #
        # @api public    
        def attribute(name, type, options = {})
          attr_name = name.to_sym

          if attributes.include?(attr_name)
            raise NameInUseError, "A Attribute called '#{attr_name.to_s}' has already been defined for #{self.inspect}."
          end

          attribute = Snowflake::Attributes.get(type).new(self, attr_name, options)

          # If this attribute is supposed to be the key then we take a note of it.
          if attribute.key?
            self.key = attr_name
          end

          attributes[name] = attribute

          # Add the attribute to the child classes only if the attribute was
          # added after the child classes' attributes have been copied from
          # the parent
          descendants.each do |descendant|
            descendant.attributes[name] ||= attribute
          end

          # Create our accessors. We don't bother if the attribute is named key, there are already
          # accessors for key.
          unless name == :key
            # create reader
            create_attribute_reader(attribute)

            # create writer
            create_attribute_writer(attribute)
          end

          attribute
        end

        # Turns on dynamic attributes -- those that have not be declared ahead of time with 
        # the attribute method -- for this element.
        #
        # @return [Element]
        #     Ourself.
        #
        # @api public
        def allow_dynamic_attributes!
          @allow_dynamic_attributes = true
          self
        end

        # Indicates that dynamic attributes -- those that have not be declared ahead of time 
        # with the attribute method -- are allowed for this element. This value defaults to
        # false.
        #
        # @return [Boolean]
        #     True if dynamic attributes are allowed, false otherwise.
        #
        # @api public
        def allow_dynamic_attributes?
          @allow_dynamic_attributes ||= false
        end

        # Retrieves the list of all attributes
        #
        # @return [Array]
        #   the list of attributes
        #
        # @api public
        def attributes
          @attributes ||= {}
        end
        
        # Indicates whether this element has a defined Attribute called +attribute_name+.
        # This includes dynamic attributes that already been created via either
        # #attributes= or #add_dynamic_attribute.
        #
        # @param [Symbol, #to_sym] attribute_name
        #     The Attribute name to look for.
        #
        # @return [Boolean]
        #     True if the element has an Attribute named +attribute_name+, false otherwise.
        #
        # @api public
        def has_attribute?(attribute_name)
          attributes.include?(attribute_name.to_sym)
        end

        # Indicates whether this element does not have a dynamically Attribute called 
        # +attribute_name+. This is the antonym of #has_attribute?
        #
        # @param [Symbol, #to_sym] attribute_name
        #     The attribute_name to look for.
        #
        # @return [Boolean]
        #     True if the element has an Attribute named +attribute_name+, false otherwise.
        #
        # @api public        
        def dynamic_attribute?(attribute_name)
          !attributes.include?(attribute_name.to_sym) || attributes[attribute_name.to_sym].is_a?(::Snowflake::Attributes::Dynamic)
        end

        def key
          @key ||= begin
            # Auto-magically create a default key attribute, if one hasn't been defined
            begin
              attribute :key, ::Snowflake::Attributes::Guid, :key => true
            rescue NameInUseError => e
              # What happens if there's is a Attribute called :key already? We get an exception that can be
              # a little obscure. We make it a little more obvious here and re-raise it.
              raise NameInUseError, "No key Attribute was defined on this Node, we tried to create one called 'key' for you but the attribute name 'key' was already in use. Please choose a attribute to be the Node key."
            end

            :key
          end
        end

        protected

        # Assign the attribute name that will represent the Element key.
        #
        # @param [Symbol, #to_sym] attribute_name
        #     The attribute name that should be the key.
        #
        # @return [Symbol]
        #     The key
        #
        # @api private
        def key=(attribute_name)
          unless @key.blank?
            raise InvalidAttributeError, "#{attribute_name.to_s} cannot be the key for #{self.to_s} as #{self.key.to_s} already is. More than one attribute cannot be the Node key."
          end

          @key = attribute_name.to_sym
        end

        private

        # @todo prevent these from being defined if they have already been defined somewhere else
        # @todo typecast
        def create_attribute_reader(attribute)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{attribute.reader_visibility}
            def #{attribute.name.to_s}
              read_attribute(:#{attribute.name.to_s})
            end
          EOS

          if attribute.is_a?(::Snowflake::Attributes::Boolean)
            class_eval <<-EOS, __FILE__, __LINE__ + 1
              #{attribute.reader_visibility}
              alias :#{attribute.name.to_s}? :#{attribute.name.to_s}
            EOS
          end
        end

        # @todo prevent these from being defined if they have already been defined somewhere else
        # @todo Handle Typecasting
        def create_attribute_writer(attribute)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{attribute.writer_visibility}
            def #{attribute.name.to_s}=(value)
              write_attribute(:#{attribute.name.to_s}, value)
            end
          EOS
        end
      end # module Attributes
    end # module Plugins
  end # module Element
end # module Snowflake