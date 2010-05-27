module RedisGraph
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

      def store!
        @node.send_command( @name, :set, to_s )
        @dirty = false
      end
    end # class Guid
  end # module Properties
end # module RedisGraph