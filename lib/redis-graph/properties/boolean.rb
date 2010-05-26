module RedisGraph
  module Properties
    class Boolean < Property
      alias_for "TrueClass"
      primitive true
      
      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options)
      end
      
      def to_s
        @raw == true ? 't' : 'f'
      end

      def raw=(raw)
        @raw =  case raw
                when TrueClass
                  raw
                when 't'
                  true
                when 'f'
                  false
                when nil
                  default
                else
                  raise ArgumentError, "Tried to assign #{raw.inspect} to a Boolean Property. Only a Boolean or String ('t' for true, 'f' for false) can be assigned to a Boolean Property."
                end

        @dirty = true
        @raw
      end
      
      def store!
        @node.send_command( @name, :set, to_s )
        @dirty = false
      end
    end # class Boolean
  end # module Properties
end # module RedisGraph