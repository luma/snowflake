module Snowflake
  module CustomAttributes
    class Set < CustomAttribute
      def initialize(name, element, raw = default)
        super( name, element, raw.is_a?(::Set) ? raw : ::Set.new(raw) )
      end

      def to_s
        @raw.join(', ')
      end

      # Converts the set to an array. The order of elements is uncertain.
      def to_a
        @raw.to_a
      end

      # Converts our Set to a Ruby Core Set
      def to_set
        @raw
      end

      def inspect
        "<#{self.class.to_s}: {#{@raw.collect {|v| "\"#{v}\""}.join(', ')}}>"
      end

      # Set the raw value of the Counter to +raw+. The new value is immediately persisted.
      #
      # @param [Enumerable] enum
      #     The new value of the Counter.
      #
      # @return [Set]
      #   self
      #
      # @api private
      def replace(enum)
        assert_persisted

        begin
          @raw =  typecast(enum)
        rescue InvalidTypeError => e
          raise InvalidTypeError, "Tried to assign #{enum.inspect} to a Set Property. Only a Set or Array can be assigned to a Set Property."
        end

        if @raw.empty?
          clear
        else
          # track changes to the set
         # send_command( :watch ) do
          # Snowflake.connection.watch( key ) do

            # TODO: There must be a better way of doing this...
            old_members = send_command( :smembers )

            members_to_add = @raw

            # @todo error checking
            Snowflake.connection.multi do
              # Remove any values that were in the set before, but aren't now
              unless old_members.empty?
                old_members = ::Set.new(old_members)

                ( old_members - @raw ).each do |v|
                  send_command( :srem, v )
                end

                members_to_add = members_to_add - old_members
              else
                members_to_add.each do |v|
                  send_command( :sadd, v )
                end
              end
            end
          
          # end

          reload
        end

        self
      end  

      # Cast +value+ to whatever type @raw should be. Raise exceptions for invalid types.
      def typecast(enum)
        case enum
        when ::Set
          enum
        when nil
          default
        when Enumerable
          ::Set.new(enum)
        else
          raise InvalidTypeError, "Cannot cast '#{value.inspect}' for #{self.inspect}."
        end
      end

      # Refresh the members of the Set from Redis.
      def reload
        @raw = ::Set.new( send_command( :smembers ) )
      end

      # Returns the number of elements. 
      def size
        send_command( :scard )
      end

      # Alias for size
      alias :length :size

      # Returns true if the set contains no elements. 
      def empty?
        send_command( :scard ) == 0
      end

      # Returns true if the set contains the given object. 
      def include?(value)
        send_command( :sismember, value )
      end

      # Retrieve a random element
      def random_element
        send_command( :srandmember )
      end

      # Adds the given object to the set and returns self. Use merge to add several 
      # elements at once. 
      def add(value)
        assert_persisted

        @raw.add(value)
        send_command( :sadd, value )

        self
      end

      # Merges the elements of the given enumerable object to the set and returns self.
      def merge(enum)
        assert_persisted

        Snowflake.connection.multi do
          enum.each do |v|
            send_command( :sadd, v )
          end
        end
      end

      # Deletes the given object from the set and returns self. Use subtract to delete 
      # several items at once. 
      def delete(value)
        assert_persisted

        @raw.delete(value)
        send_command( :srem, value )

        self
      end

      # Deletes every element that appears in the given enumerable object and returns self. 
      def subtract(enum)
        assert_persisted

        Snowflake.connection.multi do
          enum.each do |v|
            send_command( :srem, v )
          end
        end
      end

      # Removes all elements and returns self.
      def clear
        assert_persisted

        # @todo error check
        send_command( :del )
      end

      # Calls the given block once for each element in the set, passing the element as
      # parameter. 
      def each
        @raw.each {|value| yield(value) }
        self
      end

      def &(enum)
        tmp_key = ::UUIDTools::UUID.random_create.to_s

        # @todo accept an enumerable or another Set
        # @todo error handling
        
        # Snowflake.connection.watch( tmp_key, key ) do        
          results = Snowflake.connection.multi do
            enum.each { |value| Snowflake.connection.sadd( tmp_key, value) }
            send_command( :sinter, tmp_key )
            Snowflake.connection.del( tmp_key )
          end
        # end

        ::Set.new( results[ results.length - 2 ] )
      end

      alias :intersection :&

      # Returns a new set built by merging the set and the elements of the given enumerable
      # object. 
      def |(enum)
        tmp_key = ::UUIDTools::UUID.random_create.to_s

        # @todo accept an enumerable or another Set
        # @todo error handling
        results = Snowflake.connection.multi do
          enum.each { |value| Snowflake.connection.sadd( tmp_key, value) }
          send_command( :sunion, tmp_key )
          Snowflake.connection.del( tmp_key )
        end

        ::Set.new( results[ results.length - 2 ] )
      end

      alias :union :|

      # Returns a new  set built by duplicating the set, removing every element that appears
      # in the given enumerable object. 
      def -(enum)
        tmp_key = ::UUIDTools::UUID.random_create.to_s

        # @todo accept an enumerable or another Set
        # @todo error handling
        results = Snowflake.connection.multi do
          enum.each { |value| Snowflake.connection.sadd( tmp_key, value) }
          send_command( :sdiff, tmp_key )
          Snowflake.connection.del( tmp_key )
        end

        ::Set.new( results[ results.length - 2 ] )
      end

      alias :difference :-

      def coerce(other)
        case other
        when Array
          [@raw, ::Set.new(other)]
        when ::Set
          [@raw, other]
        else
          super
        end
      end

      # Returns true if two sets are equal.    
      # @api public
      def ==(other)
        case other
        when self.class
          inspect == other.inspect
        when ::Set
          @raw == other
        else
          super
        end
      end

      # @api public
      def eql?(other)
        self == other
      end

      class << self      
        # Retrieve a CustomAttribute for +element+ by it's +name+, if no CustomAttribute 
        # can be found it creates new one with the default value
        #
        # @param [Element] element
        #     The Element, to find Counter +name+ for.
        # @param [String, #to_string] key
        #     The name of Counter we're looking for.
        #
        # @return [Element, nil]
        #   A Element with the key of +key+
        #   If no Element was found with the key of +key+
        # 
        # @api public      
        def get(element, name)

          self.new(name, element, element.send_command( name, :smembers ) )
        end
      end

      private
  
      def default
        ::Set.new
      end
  
    end # class Set
  end # module CustomAttributes
end # module Snowflake