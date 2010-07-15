module RedisGraph
  module Element
    module Plugins
      module CustomAttributes
        Model.add_extensions self

        def self.extended(model)
          model.send(:include, InstanceMethods)
        end

        module InstanceMethods
          protected

          # All custom attributes for this element
          #
          # @return [Hash<Counter>]
          #   the Hash of custom attributes for this element.
          #
          # @api private          
          def custom_attributes
            @custom_attributes ||= {}
          end

          # Reads the value of the Counter called +name+.
          #
          # @param [CustomAttribute] klass
          #   The class of CustomAttribute to use.
          #
          # @param [#to_sym] name
          #     The name of the Counter value to read.
          #
          # @return [Any]
          #   +value+
          #
          # @api private          
          def read_custom_attribute(klass, name)
            counter = if custom_attributes.include?(name.to_sym)
                        custom_attributes[name.to_sym]
                      else
                        # If it hasn't been loaded yet, do so...
                        custom_attributes[name.to_sym] = klass.get( self, name )
                      end
            
            counter
          end

          # Writes +value+ to the Counter called +name+
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
          # @api private
          def write_custom_attribute(klass, name, value)
            counter = read_custom_attribute(:counter, name)
            counter.replace(value)
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
          create_custom_attribute(RedisGraph::CustomAttributes::Counter, name.to_sym, options)
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
          create_custom_attribute(RedisGraph::CustomAttributes::Set, name.to_sym, options)
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
          create_custom_attribute(RedisGraph::CustomAttributes::List, name.to_sym, options)
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
  end # module Element
end # module RedisGraph