module RedisGraph
  module Properties
    class Integer < Property
      alias_for ::Integer
      primitive true
      
      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options)
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

      def store!
        @node.send_command( @name, :set, to_s )
        @dirty = false
      end
    end
  end # module Properties
end # module RedisGraph