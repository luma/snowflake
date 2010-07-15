module Snowflake
  module Properties
    class Guid < Property
      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options.merge(
          :default => ::UUIDTools::UUID.random_create.to_s
        ))
      end

      def to_s
        @raw
      end

      def raw=(raw)
        @dirty = true
        @raw = raw != nil ? raw.to_s : default
      end

      protected

      def store_raw
        @node.send_command( @name, :set, to_s )
      end
    end # class Guid
  end # module Properties
end # module Snowflake