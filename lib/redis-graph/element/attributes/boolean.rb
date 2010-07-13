module RedisGraph
  module Attributes
    class Boolean < Attribute
      alias_for "TrueClass"
      primitive true

      def initialize(node, name, options = {})
        super(node, name, options)
      end

      # Convert +value+ to a String
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
        when 't'
          true
        when 'f'
          false
        when nil
          default
        else
          raise ArgumentError, "Tried to cast #{value.inspect} to a Boolean Property. Only a Boolean or String ('t' for true, 'f' for false) can be assigned to a Boolean Property."
        end
      end
    end # class Boolean
  end # module Attributes
end # module RedisGraph