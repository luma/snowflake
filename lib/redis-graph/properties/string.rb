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
        @raw   = raw.to_s
      end
      
      def store!
        @node.send_command( @name, :set, to_s )
        @dirty = false
      end
    end
  end # module Properties
end # module RedisGraph