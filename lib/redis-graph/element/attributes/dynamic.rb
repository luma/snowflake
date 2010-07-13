module RedisGraph
  module Attributes
    # This Attribute is used for all dynamically created attributes and provides a 
    # convienant place to any hehaviour they need.
    class Dynamic < Attribute
      def initialize(node, name, options = {})
        super(node, name, options)
      end

      # Convert +value+ to a String
      def dump(value)
        value.to_s
      end

      # Dynamic attributes can never be the key
      def key?
        false
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
        if value.blank?
          default
        else
          value.to_s
        end
      rescue NoMethodError => e
        raise ArgumentError, "Tried to cast #{value.inspect} to a Guid Attribute. Only values that can be cast to a string (via #to_s) can be assigned to a Guid Attribute."
      end

    end # class Dynamic
  end # module Attributes
end # module RedisGraph