module RedisGraph
  module Attributes
    class String < Attribute
      alias_for ::String
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
        if value == nil
          default
        else
          value.to_s
        end
      rescue NoMethodError => e
        raise ArgumentError, "Tried to cast #{value.inspect} to a String Attribute. Only values that can be cast to a string (via #to_s) can be assigned to a String Attribute."
      end

    end # class String
  end # module Attributes
end # module RedisGraph