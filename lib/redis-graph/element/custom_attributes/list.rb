module RedisGraph
  module CustomAttributes
    class List < CustomAttribute
      def initialize(name, element, raw = default)
        super( name, element, raw.is_a?(Array) ? raw : raw.to_a )
      end

      def to_s
        @raw.join(', ')
      end

      # Converts the set to an array. The order of elements is uncertain.
      def to_a
        @raw
      end

      # Converts our List to a Ruby Core Set
      def to_set
        ::Set.new(@raw)
      end

      def inspect
        "<#{self.class.to_s}: {#{@raw.collect {|v| "\"#{v}\""}.join(', ')}}>"
      end

      # Set the raw value of the Counter to +raw+. The new value is immediately persisted.
      #
      # @param [Enumerable] enum
      #     The new value of the Counter.
      #
      # @return [List]
      #   self
      #
      # @api private
      def replace(enum)
        assert_persisted

        begin
          @raw = typecast(enum)
        rescue InvalidTypeError => e
          raise InvalidTypeError, "Tried to assign #{enum.inspect} to a List Property. Only a Set or Enumerable can be assigned to a List Property."
        end

        # @todo error check
        results = RedisGraph.connection.multi do
          clear

          # @bug This triggers incorrect responses from Redis, why?
          # enum.each_index do |i|
          #   send_command( :lset, i, enum[i] )
          # end

          enum.each_index do |i|
            send_command( :rpush, enum[i] )
          end
          
          send_command( :lrange, 0, -1 )
        end

        @raw = results.last
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
          Array.new(enum)
        else
          raise InvalidTypeError, "Cannot cast '#{value.inspect}' for #{self.inspect}."
        end
      end

      # Refresh the members of the List from Redis
      def reload
        @raw = send_command( :lrange, 0, -1 )
      end

      # Returns the number of elements. 
      def length
        send_command( :llen ).to_i
      end

      # Returns true if the set contains no elements. 
      def empty?
        length == 0
      end

      # Returns true if the set contains the given object. 
      def include?(value)
        send_command( :lrange, 0, -1 ).include?(value.to_s)
      end
      
      # This accepts a single index, an index and length, or a Range.
      def [](*args)
        # Dude, this is fugly
        if args.length == 2
          slice( args.first, args[1] )
        elsif args.first.is_a?(Range)
          send_command( :lrange, args.first.first, args.first.last )

        else
          send_command( :lindex, args.first )
        end
      end
      
      def []=(*args)
        assert_persisted

        # @todo: Dude, this is fugly. It needs refactoring into several methods.
        if args.length == 3
          slice_and_replace(args.first, args[1], args[2])

        elsif args.first.is_a?(Range)
          # @todo: bounds checking needed on slicing
          values = args.last
          
          # If slicing the list value must be of equal size to the sliced range
          if !values.is_a?(Array) || args.first.to_a.length != values.length
            raise ArgumentError, "When overwriting a range of elements within the List, the array of values you wish to assign must be equal to the number of elements you wish to overwrite."
          end

          RedisGraph.connection.multi do
            r = 0
            args.first.each do |i|
              send_command( :lset, i, values[r] )
              r = r + 1
            end
          end
        else          
          # track changes to the list
          # @todo change this to block form, send_command needs to accept a block
          #send_command( :watch ) do
            if args.first >= length || args.first < (length * -1)
              raise ArgumentError, "Out of range for List"
            end

            RedisGraph.connection.multi do
              send_command( :lset, args.first, args.last )
            end
        
          #end
        end
      end

      def slice(index, length)
        send_command( :lrange, index, index + length - 1 )
      end

      def slice_and_replace(index, slice_length, values)
        unless values.is_a?(Array) 
          raise ArgumentError, "You must provide an array of replacement elements when replacing a slice of a list."
        end

        # If slicing the list value must be of equal size to the sliced range
        unless slice_length == values.length
          raise ArgumentError, "When overwriting a range of elements within the List, the array of values you wish to assign must be equal to the number of elements you wish to overwrite."
        end

        # @todo: bounds checking needed on slicing
        end_index = index + slice_length - 1
        if index < 0 || end_index >= length
          raise ArgumentError, "When overwriting a range of elements within the List, the array of values you wish to assign must be equal to the number of elements you wish to overwrite."
        end

        # @todo error check
        RedisGraph.connection.multi do
          r = 0
          (index..end_index).each do |i|
            send_command( :lset, i, values[r] )
            r = r + 1
          end
        end
        
        self
      end

      # Append—Pushes the given object on to the end of this array. This expression returns 
      # the array itself, so several appends may be chained together. 
      def <<(value)
        assert_persisted

        # @todo error check
        send_command( :rpush, value )
        self
      end
      alias :push :<<

      # Removes the last element from self and returns it, or nil if the array is empty.
      def pop
        assert_persisted

        # @todo error check
        send_command( :rpop, value )
        self
      end

      # Deletes items from self that are equal to obj. If the item is not found, returns 
      # nil. If the optional code block is given, returns the result of block if the item 
      # is not found. 
      def delete(value)
        assert_persisted

        # @todo error check
        if send_command( :lrem, 0, value ) == 0
          # return nil, if nothing was deleted
          nil
        end

        yield if block_given?
      end

      # Deletes every element of self for which block evaluates to true.
      def delete_if(&block)
        @raw.delete_if(&block)
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
      
      # Calls the given block once for each element in the set, passing the element as
      # parameter. 
      def collect(&block)
        @raw.collect(&block)
      end
      alias :map :collect

      # Invokes the block once for each element of self, replacing the element with the 
      # value returned by block.
      def collect!(&block)
        assert_persisted

        @raw.collect!(&block)

        RedisGraph.connection.multi do
          @raw.each_index do |i|
            send_command( :lset, i, @raw[i] )
          end
        end

        self
      end
      alias :map! :collect!
      
      # Returns a copy of self with all nil elements removed.
      def compact
        delete_if {|value| value == nil || value.empty? }
      end

      # Removes nil elements from array. Returns nil if no changes were made. 
      def compact!
        assert_persisted

        @raw.compact!

        # @todo error checking
        if send_command( :lrem, 0, "" ) == 0
          nil
        else
          self
        end
      end

      def coerce(other)
        case other
        when Array
          [@raw, other]
        when ::Set
          [@raw, other.to_a]
        else
          super
        end
      end

      # Returns true if two sets are equal.    
      # @api public
      def ==(other)
        case other
        when self.class
          @raw == other.to_a
        when Array
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
          self.new(name, element, element.send_command( name, :lrange, 0, -1 ) )
        end
      end

      private
  
      def default
        []
      end
  
    end # class List
  end # module CustomAttributes
end # module RedisGraph