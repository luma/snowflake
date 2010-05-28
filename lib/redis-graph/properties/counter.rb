module RedisGraph
  module Properties
    class Counter < Property
      def initialize(node, name, raw_value, options = {})        
        super(node, name, raw_value, options.merge(
          :default => 0
        ))
      end

      def to_i
        @raw
      end
      alias :to_int :to_i

      def raw=(raw)
        @raw =  unless raw.nil?
                  raw.to_i
                else
                  default
                end

        @dirty = true
        @raw
      end

      # Mimic Integer for common methods
      %w{+ - * /}.each do |operator|
        define_method operator do |*args|
          # @todo I'm not doing any typecasting of the value(s) in args to_i, I probably should be...
          to_i.send(operator, *args)
        end
      end

      # methods forwarded to @value
      %w{== < > <=> to_s}.each do |meth|
        define_method meth do |*other|
          to_i.send(meth, *other)
        end
      end

      # Pretend to be an Integer
      def coerce(other)
        case other
        when Integer
          [to_i, other.to_i]
        else
          super
        end
      end

      def incriment!(by = 1)
        @node.send_command( nil, :hincrby, @name, by.to_i )
        @raw = @raw + by.to_i
      end

      def decriment!(by = 1)
        @node.send_command( nil, :hincrby, @name, by.to_i * -1 )
        @raw = @raw - by.to_i
      end

      protected

      def store_raw
        @node.send_command( nil, :hset, @name, to_s )
      end

    end
  end # module Properties
end # module RedisGraph