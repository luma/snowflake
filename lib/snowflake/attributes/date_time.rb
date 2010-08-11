
module Snowflake
  module Attributes
    class DateTime < Attribute
      alias_for ::DateTime
      primitive true

      def initialize(node, name, options = {})
        if options.include?(:default)
          case options[:default]
          when ::String
            options[:default] = ::DateTime.parse( options[:default] )
          when ::DateTime
          else
            raise ArgumentError, "The default for a DateTime attribute must be either a Ruby DateTime or a String that can be converted to a DateTIme (using Datetime#parse)"
          end
        end

        super(node, name, options)
      end

      # Convert +value+ to a String. This should only ever be called with a +value+ that's been typecast.
      def dump(value)
        case value
        when nil
          nil
        else
          value.to_s
        end
      end

      # Typecasts +value+ to the correct type for this Attribute.
      #
      # @param [Any] value
      #     The value to convert.
      #
      # @return [Any]
      #     A typecast version of +value+.
      # 
      # @api semi-public
      def typecast(value)
        case value
        when ::DateTime
          value
        else
          ::DateTime.parse( value )
        end
      rescue ArgumentError => e
        raise ArgumentError, "Tried to cast #{value.inspect} to a DateTime Attribute. Only DateTime objects and strings that are formatted as string can be typecast to DateTime"
      end

    end # class String
  end # module Attributes
end # module Snowflake