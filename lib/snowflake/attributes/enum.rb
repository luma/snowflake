
module Snowflake
  module Attributes
    class Enum < Attribute
      def initialize(node, name, options = {})
        unless options.include?(:values)
          raise ArgumentError, "An Enum attribute must have a :values option."
        end

        options[:values] = options[:values].collect {|v| v.to_sym }
        super(node, name, options)
      end

      # Convert +value+ to a String. This should only ever be called with a +value+ that's been typecast.
      def dump(value)
        case value
        when nil
          nil
        else
          @options[:values].index(value) + 1
        end
      end

      # Typecasts +value+ to the correct type for this Attribute.
      #
      # @param [Any] value
      #     The value to convert.
      #
      # @return [Symbol, #default]
      #     A typecast version of +value+. Usually a Symbol
      #     the return value from #default.
      # 
      # @api semi-public
      def typecast(value)
        case value
        when nil
          default
        when ::String
          cast_value = value.to_sym

          unless @options[:values].include?(cast_value)
            raise ArgumentError, "Could assign #{cast_value.inspect} to #{@name}, it must be one of #{@options[:values].join(', ')}."
          end

          cast_value
        when Symbol
          unless @options[:values].include?(value)
            raise ArgumentError, "Could assign #{value.inspect} to #{@name}, it must be one of #{@options[:values].join(', ')}."
          end
          
          value
        when ::Integer
          if value == 0 || (cast_value = @options[:values][value - 1]) == nil
            raise ArgumentError, "Could not assign #{value.inspect} to #{@name}, possible integer index values are 1 - #{@options[:values].length}"
          end
          
          cast_value
        else
          raise ArgumentError, "Could not cast #{value.inspect} to a Enum Attribute for #{@name}."
        end
      end

    end # class String
  end # module Attributes
end # module Snowflake