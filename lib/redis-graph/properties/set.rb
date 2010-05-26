module RedisGraph
  module Properties
    class Set < Property
      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options.merge(
          :default => ::Set.new
        ))
      end
      
      def raw=(raw)
        @raw =  case raw
                when Array
                  ::Set.new(raw)
                when ::Set
                  raw
                when nil
                  default
                else
                  raise ArgumentError, "Tried to assign #{raw.inspect} to a Set Property. Only a Set or Array can be assigned to a Set Property."
                end

        @dirty = true
        @raw
      end

      # Mimic Set for common methods
      %w{& + - ^ | == to_s push unshift add << <=> map collect include? length first inject}.each do |operator|
        define_method operator do |*args|
          # @todo I'm not doing any typecasting of the value(s) in args to_i, I probably should be...
          @raw.send(operator, *args)
        end
      end


      def coerce(other)
        case other
        when Array
          [@raw.to_a, other]
        when ::Set
          [@raw, other]
        else
          super
        end
      end

      # Store a Hash Value into
      def store!
        # TODO: There must be a better way of doing this...
        old_members = @node.send_command( @name, :smembers )

        members_to_add = @raw

        # Remove any values that were in the set before, but aren't now
        unless old_members.empty?
          old_members = ::Set.new(old_members)

          ( old_members - @raw ).each do |v|
            @node.send_command( @name, :sremove, v )
          end
          
          members_to_add = members_to_add - old_members
        else
          members_to_add.each do |v|
            @node.send_command( @name, :sadd, v )
          end
        end
        
        @dirty = false
      end
    end
  end # module Properties
end # module RedisGraph