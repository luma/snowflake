module Snowflake
  module Element
    module Plugins
      module Sets
        Model.add_extensions self

        def self.extended(model)
          model.send(:include, InstanceMethods)
        end

        module InstanceMethods
          protected

          # All sets for this element
          #
          # @return [Hash<Counter>]
          #   the Hash of sets for this element.
          #
          # @api private          
          def sets
            @sets ||= {}
          end

          # Reads the value of the Set called +name+.
          #
          # @param [#to_sym] name
          #     The name of the Set value to read.
          #
          # @return [Any]
          #   +value+
          #
          # @api private          
          def read_set(name)
            set = if sets.include?(name.to_sym)
                    sets[name.to_sym]
                  else
                    # If it hasn't been loaded yet, do so...
                    sets[name.to_sym] = CustomAttributes::Set.get( self, name )
                  end
            
            set
          end

          # Writes +value+ to the Set called +name+
          #
          # @param [#to_sym] name
          #     The name of the Set value to write to.
          #
          # @param [Any] value
          #     The value to assign to Set called +name+.
          #
          # @return [Any]
          #   +value+
          #
          # @api private
          def write_set(name, value)
            set = read_set(name)
            set.replace(value)
          end

        end # module InstanceMethods

        # Declare a Set called +name+ for this element.
        #
        # @param [Symbol, #to_sym] name
        #   The name of the new Set.
        # @param [Hash(Symbol => String)] options
        #   A hash of available options
        #
        # @return [Symbol]
        #   the set name
        #
        # @api public
        def set(name, options = {})
          set_name = name.to_sym

          # @todo we need to validate all extended attribute names against each other

          if sets.include?(set_name)
            raise NameInUseError, "A Set called '#{name.to_s}' has already been defined for #{self.inspect}."
          end

          sets << set_name

          create_set_reader(set_name, options)
          create_set_writer(set_name, options)
          
          set_name
        end

        # All sets declared for this element
        #
        # @return [Set<Symbol>]
        #   a Set of Symbols, representing the names of the sets for this element
        #
        # @api public
        def sets
          @sets ||= ::Set.new
        end

        private

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_set_reader(set_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:reader_visibility] || 'public'}
            def #{set_name.to_s}
              read_set(:#{set_name.to_s})
            end
          EOS
        end

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_set_writer(set_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:writer_visibility] || 'public'}
            def #{set_name.to_s}=(value)
              write_set(:#{set_name.to_s}, value)
            end
          EOS
        end
      end # module Sets
    end # module Plugins
  end # module Element
end # module Snowflake