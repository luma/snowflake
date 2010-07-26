module Snowflake
  module Plugins
    module CustomAttributes
      Model.add_extensions self

      def self.extended(model)
        model.send(:include, InstanceMethods)
      end

      module InstanceMethods
        # Indicates whether this element has a defined CustomAttribute called +name+.
        #
        # @param [Symbol, #to_sym] name
        #     The CustomAttribute name to look for.
        #
        # @return [Boolean]
        #     True if the element has an CustomAttribute named +name+, false otherwise.
        #
        # @api public
        def custom_attribute?( name )
          self.class.custom_attribute?( name )
        end
        
        protected

        # All custom attributes for this element
        #
        # @return [Hash<CustomAttribute>]
        #   the Hash of custom attributes for this element.
        #
        # @api private          
        def custom_attributes
          @custom_attributes ||= {}
        end

        # Reads the value of the CustomAttribute called +name+.
        #
        # @param [CustomAttribute] klass
        #   The class of CustomAttribute to use.
        #
        # @param [#to_sym] name
        #     The name of the Counter value to read.
        #
        # @return [Any, nil]
        #   The value of the CustomAttribute;
        #   Nil, if there was no CustomAttribute called +name+.
        #
        # @api private          
        def read_custom_attribute(klass, name)
          unless self.class.custom_attribute?( name )
            return nil
          end
          
          if custom_attributes.include?(name.to_sym)
            custom_attributes[name.to_s]
          else
            # If it hasn't been loaded yet, do so...
            custom_attributes[name.to_s] = klass.get( self, name )
          end
        end

        # Writes +value+ to the Counter called +name+
        #
        # We won't even bother if there are other errors. There's a couple of reasons
        # for this:
        # * Custom Attributes are persisted immediately, outside of the attribute workflow (load -> validate -> save), and that workflow should be completed before modifing custom attributes so as not to lose state;
        # * It would make who's responsible for error oblique.
        #
        # *Note 1:* we explicity raise an exception for this, this is to ensure that 
        # it's explicity handled and not lost inside the errors collection.
        #
        # *Node 2:* we currently don't have any checking for this condition when 
        # modifying custom attributes directly i.e. element.custom_count.incriment. This
        # may need to change but, until it does, consider this your training wheels.
        #
        # If errors occur while persisting custom attributes will raise a
        # CouldNotPersistCustomAttributeError exception. I'd prefer it if I could just
        # shove the errors into the errors collection and use #valid? But #valid? clears
        # all errors so custom errors like these would be lost. Instead we put the error 
        # in the errors collection then raise an exception, so custom attributes failing
        # to persist must be explicitly handled.
        #
        # @param [CustomAttribute] klass
        #   The class of CustomAttribute to use.
        #
        # @param [#to_sym] name
        #     The name of the Counter value to write to.
        #
        # @param [Any] value
        #     The value to assign to Counter called +name+.
        #
        # @return [Any]
        #   +value+
        #
        # @raise [CouldNotPersistCustomAttributeError]
        #   The custom attribute could not be overwritten.
        #
        # @api private
        def write_custom_attribute(klass, name, value)
          unless valid?
            raise CustomAttributeError, "There are existing validation errors, please correct them before modifying any of the following: #{self.class.custom_attribute_names.join(', ')}"
          end
            
          attribute = read_custom_attribute( klass, name )
          if attribute == nil
            raise NoMethodError, "There was custom attribute called '#{name.to_s}' for #{self.inspect}."
          end
          
          result = attribute.replace( value )
          
          # If result is true, we're good, anything else is an error message
          unless result == true
            # @todo this is really fugly. I'd prefer it if I could just shove the errors
            # into the errors collection and use #valid? But #valid? clears all errors
            # so custom errors like these would be lost. Instead we put the error in the
            # errors collection then raise an exception, so custom attributes failing
            # to persist must be explicitly handled.
            errors[name] = result
            raise CouldNotPersistCustomAttributeError, result
          end

          attribute
        end

      end # module InstanceMethods

      # All custom attributes declared for this element
      #
      # @return [Set<Symbol>]
      #   a Set of Symbols, representing the custom attribute names for this element
      #
      # @api public
      def custom_attributes
        @custom_attributes ||= ::Set.new
      end

      # Indicates whether this element has a defined CustomAttribute called +name+.
      #
      # @param [Symbol, #to_sym] name
      #     The CustomAttribute name to look for.
      #
      # @return [Boolean]
      #     True if the element has an CustomAttribute named +name+, false otherwise.
      #
      # @api public
      def custom_attribute?( name )
        custom_attributes.include?( name.to_sym )
      end


      # Human readible names of all custom attribute types.
      #
      # @return [Array<String>]
      #   The custom attribute names as human readible strings.
      #
      # @api semi-public
      def custom_attribute_names
        ['Counters', 'Sets', 'Lists']
      end

      # Declare a Counter called +name+ for this element.
      #
      # @param [Symbol, #to_sym] name
      #   The name of the new Counter.
      # @param [Hash(Symbol => String)] options
      #   A hash of available options.
      #
      # @return [Symbol]
      #   the counter name.
      #
      # @api public
      def counter(name, options = {})
        create_custom_attribute(Snowflake::CustomAttributes::Counter, name.to_sym, options)
      end

      # Declare a Set called +name+ for this element.
      #
      # @param [Symbol, #to_sym] name
      #   The name of the new Set.
      # @param [Hash(Symbol => String)] options
      #   A hash of available options.
      #
      # @return [Symbol]
      #   the Set name.
      #
      # @api public
      def set(name, options = {})
        create_custom_attribute(Snowflake::CustomAttributes::Set, name.to_sym, options)
      end

      # Declare a List called +name+ for this element.
      #
      # @param [Symbol, #to_sym] name
      #   The name of the new List.
      # @param [Hash(Symbol => String)] options
      #   A hash of available options.
      #
      # @return [Symbol]
      #   the List name.
      #
      # @api public
      def list(name, options = {})
        create_custom_attribute(Snowflake::CustomAttributes::List, name.to_sym, options)
      end
      
      protected
      
      # Declare a CustomAttribute called +name+, and of Class +klass+, for this element.
      #
      # @param [CustomAttribute] klass
      #   The class of CustomAttribute to use.
      # @param [Symbol] name
      #   The name of the new CustomAttribute.
      # @param [Hash(Symbol => String)] options
      #   A hash of available options
      #
      # @return [Symbol]
      #   the custom element name
      #
      # @api public
      def create_custom_attribute(klass, name, options = {})
        # We need to validate all extended attribute names against each other, name must 
        # be unique across the entire element
        # @todo check against attributes, as well.
        if custom_attributes.include?(name)
          raise NameInUseError, "A Counter called '#{name.to_s}' has already been defined for #{self.inspect}."
        end

        if Model.restricted_name?(name)
          raise ArgumentError, "'#{name}' is a restricted name, and cannot be used for as CustomAttribute name. The following are all restricted names: #{Model.restricted_names.join(', ')}"
        end

        custom_attributes << name

        create_custom_attribute_reader(klass, name, options)
        create_custom_attribute_writer(klass, name, options)

        name
      end

      private

      # @todo prevent these from being defined if they have already been defined somewhere else
      def create_custom_attribute_reader(klass, counter_name, options)
        class_eval <<-EOS, __FILE__, __LINE__ + 1
          #{options[:reader_visibility] || 'public'}
          def #{counter_name.to_s}
            read_custom_attribute(#{klass.to_s}, :#{counter_name.to_s})
          end
        EOS
      end

      # @todo prevent these from being defined if they have already been defined somewhere else
      def create_custom_attribute_writer(klass, counter_name, options)
        class_eval <<-EOS, __FILE__, __LINE__ + 1
          #{options[:writer_visibility] || 'public'}
          def #{counter_name.to_s}=(value)
            write_custom_attribute(#{klass.to_s}, :#{counter_name.to_s}, value)
          end
        EOS
      end
    end # module Counters
  end # module Plugins
end # module Snowflake