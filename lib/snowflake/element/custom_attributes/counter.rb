module Snowflake
  module CustomAttributes
    class Counter < CustomAttribute
      def initialize(name, element, raw = default)
        super name, element, raw.to_i
      end
  
      def to_i
        @raw
      end
      alias :to_int :to_i

      # Refresh the members of the Counter from Redis
      def reload
        @raw = send_command( :get )
      end

      # Set the raw value of the Counter to +raw+. The new value is immediately persisted.
      #
      # @param [Integer, #to_i] raw
      #     The new value of the Counter.
      #
      # @return [Counter]
      #   self
      #
      # @api semi-public
      def replace(raw)
        assert_persisted

        # I'd rather this was in the counters plugin than here...bah!
        unless @element.persisted?
          raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify a counter until after an element is persisted."
        end

        @raw =  typecast(raw)
        send_command( :set, @raw )

        self
      end

      # Cast +value+ to whatever type @raw should be. Raise exceptions for invalid types.
      # @api semi-public
      def typecast(value)
        case value
        when nil
          default
        when Integer
          value
        when Float, String
          value.to_s
        else
          raise InvalidTypeError, "Cannot cast '#{value.inspect}' for #{self.inspect}."
        end
      end

      # Mimic Integer for common methods
      %w{+ - * /}.each do |operator|
        define_method operator do |*args|
          # @todo I'm not doing any typecasting of the value(s) in args to_i, I probably should be...
          to_i.send(operator, *args)
        end
      end

      # methods forwarded to @raw
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

      # Incriment the Counter by +by+, where +by+ defaults to 1. The new value is 
      # immediately persisted.
      #
      # @param [Integer, #to_i] by
      #     The value to incriment the Counter by, defaults to 1.
      #
      # @return [Any]
      #   +value+
      #
      # @api private
      def incriment(by = 1)
        assert_persisted

        # I'd rather this was in the counters plugin than here...bah!
        unless @element.persisted?
          raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify a counter until after an element is persisted."
        end

        @raw = send_command( :incrby, by.to_i )
      end
      alias :incr :incriment

      # Decriment the Counter by +by+, where +by+ defaults to 1. The new value is 
      # immediately persisted.
      #
      # @param [Integer, #to_i] by
      #     The value to decriment the Counter by, defaults to 1.
      #
      # @return [Any]
      #   +value+
      #
      # @api private
      def decriment(by = 1)
        assert_persisted

        # I'd rather this was in the counters plugin than here...bah!
        unless @element.persisted?
          raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify a counter until after an element is persisted."
        end

        @raw = send_command( :decrby, by.to_i )
      end
      alias :decr :decriment

      private
  
      def default
        0
      end
  
    end # class Counter
  end # module CustomAttributes
end # module Snowflake