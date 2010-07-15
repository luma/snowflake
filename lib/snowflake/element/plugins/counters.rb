module Snowflake
  module Element
    module Plugins
      module Counters
        Model.add_extensions self

        def self.extended(model)
          model.send(:include, InstanceMethods)
        end

        module InstanceMethods
          protected

          # All counters for this element
          #
          # @return [Hash<Counter>]
          #   the Hash of Counters for this element.
          #
          # @api private          
          def counters
            @counters ||= {}
          end

          # Reads the value of the Counter called +name+.
          #
          # @param [#to_sym] name
          #     The name of the Counter value to read.
          #
          # @return [Any]
          #   +value+
          #
          # @api private          
          def read_counter(name)
            counter = if counters.include?(name.to_sym)
                        counters[name.to_sym]
                      else
                        # If it hasn't been loaded yet, do so...
                        counters[name.to_sym] = CustomAttributes::Counter.get( self, name )
                      end
            
            counter
          end

          # Writes +value+ to the Counter called +name+
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
          def write_counter(name, value)
            counter = read_counter(name)
            counter.replace(value)
          end

        end # module InstanceMethods

        # Declare a Counter called +name+ for this element.
        #
        # @param [Symbol, #to_sym] name
        #   The name of the new Counter.
        # @param [Hash(Symbol => String)] options
        #   A hash of available options
        #
        # @return [Symbol]
        #   the counter name
        #
        # @api public
        def counter(name, options = {})
          counter_name = name.to_sym

          # @todo we need to validate all extended attribute names against each other

          if counters.include?(counter_name)
            raise NameInUseError, "A Counter called '#{name.to_s}' has already been defined for #{self.inspect}."
          end

          counters << counter_name

          create_counter_reader(counter_name, options)
          create_counter_writer(counter_name, options)
          
          counter_name
        end

        # All counters declared for this element
        #
        # @return [Set<Symbol>]
        #   a Set of Symbols, representing the counter names for this element
        #
        # @api public
        def counters
          @counters ||= ::Set.new
        end
        
        private

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_counter_reader(counter_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:reader_visibility] || 'public'}
            def #{counter_name.to_s}
              read_counter(:#{counter_name.to_s})
            end
          EOS
        end

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_counter_writer(counter_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:writer_visibility] || 'public'}
            def #{counter_name.to_s}=(value)
              write_counter(:#{counter_name.to_s}, value)
            end
          EOS
        end
      end # module Counters
    end # module Plugins
  end # module Element
end # module Snowflake