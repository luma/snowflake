module RedisGraph
  module Properties
    class List < Property
      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options.merge(
          :default => []
        ))
      end
      
      def raw=(raw)
        @raw =  case raw
                when Array
                  raw
                when nil
                  @options[:default] || nil
                else
                  raise ArgumentError, "Tried to assign #{raw.inspect} to a List Property. Only an Array can be assigned to a Hash Property."
                end

        @dirty = true
        @raw
      end

      # Mimic Array for common methods
      %w{& + - ^ | [] []= == to_s push unshift << <=> map collect include? length first inject}.each do |operator|
        define_method operator do |*args|
          # @todo I'm not doing any typecasting of the value(s) in args to_i, I probably should be...
          @raw.send(operator, *args)
        end
      end

      # Pretend to be an Integer
      def coerce(other)
        case other
        when Array
          [@raw, other]
        else
          super
        end
      end

      def store!
        @node.send_command( @name, :del )
        
        # @todo These should be batched
        @raw.each do |value|
          @node.send_command( @name, :rpush, value )
        end
        
        @dirty = false
      end
    end
  end # module Properties
end # module RedisGraph