module RedisGraph
  module Attributes
    class Integer < Attribute
      alias_for ::Integer
      primitive true
      
      def initialize(node, name, options = {})
        super(node, name, options)
      end

      # Convert +value+ to a String
      def dump(value)
        value.to_s
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
        value.to_i
      rescue NoMethodError => e
        raise ArgumentError, "Tried to cast #{value.inspect} to a Integer Attribute. Only values that can be cast to a integer (via #to_i) can be assigned to a Integer Attribute."
      end
    end
  end # module Attribute
end # module RedisGraph