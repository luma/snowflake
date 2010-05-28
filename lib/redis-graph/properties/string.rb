module RedisGraph
  module Properties
    class String < Property
      alias_for ::String
      primitive true

      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options)
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
    end
  end # module Properties
end # module RedisGraph