module Snowflake
  module Attributes
    class Boolean < Attribute
      alias_for "TrueClass"
      primitive true

      def initialize(node, name, options = {})
        super(node, name, options)
      end

      # Convert +value+ to a String. This should only ever be called with a +value+ that's been typecast.
      def dump(value)
        value == true ? 't' : 'f'
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
        when TrueClass
          value
        when 1, 't', '1'
          true
        when 0, 'f', '0'
          false
        else
          raise ArgumentError, "Tried to cast #{value.inspect} to a Boolean Property. Only a Boolean or String ('t' for true, 'f' for false) can be assigned to a Boolean Property."
        end
      end
    end # class Boolean
  end # module Attributes
end # module Snowflake