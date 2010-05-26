module RedisGraph
  module Properties
    class Hash < Property
      alias_for ::Hash
      primitive true

      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options)
      end
      
      def raw=(raw)
        raise ArgumentError, "Tried to assign #{raw.inspect} to a Hash Property. Only a Hash can be assigned to a Hash Property." unless raw.is_a?(::Hash)
        @dirty = true
        @raw = raw
      end

      # Store a Hash Value into 
      def store!
        @node.send_command( @name, :hmset, @raw )
        @dirty = false
      end
    end
  end # module Properties
end # module RedisGraph