module RedisGraph
  module Attributes
    class Guid < Attribute
      def initialize(node, name, options = {})
        super(node, name, options.merge(
          :default => lambda {|n, a| ::UUIDTools::UUID.random_create.to_s }
        ))
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
        if value.blank?
          default
        else
          value.to_s
        end
      rescue NoMethodError => e
        raise ArgumentError, "Tried to cast #{value.inspect} to a Guid Attribute. Only values that can be cast to a string (via #to_s) can be assigned to a Guid Attribute."
      end

    end # class Guid
  end # module Attributes
end # module RedisGraph