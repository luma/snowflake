module RedisGraph
  class Set
    attr_reader :name, :element

    def initialize(name, element, raw = ::Set.new)
      @name = name
      @element = element
      @raw = raw.is_a?(::Set) ? raw : ::Set.new(raw)
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

      @raw =  case enum
              when Array
                ::Set.new(enum)
              when ::Set
                enum
              when nil
                default
              else
                raise ArgumentError, "Tried to assign #{enum.inspect} to a Set Property. Only a Set or Array can be assigned to a Set Property."
              end

      if @raw.empty?
        clear
      else
        # track changes to the set
        send_command( :watch )

        # TODO: There must be a better way of doing this...
        old_members = send_command( :smembers )

        members_to_add = @raw

        # @todo error checking
        RedisGraph.connection.multi do
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

        reload
      end
      
      self
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

      RedisGraph.connection.multi do
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

      RedisGraph.connection.multi do
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
      assert_persisted

      tmp_key = ::UUIDTools::UUID.random_create.to_s

      # @todo error handling
      RedisGraph.connection.multi do
        enum.each { |value| RedisGraph.connection.sadd( tmp_key, value) }
        set = ::Set.new(send_command( :sinter, tmp_key ))
        RedisGraph.connection.del( tmp_key )
      end

      set
    end

    alias :intersection :&
    
    # Returns a new set built by merging the set and the elements of the given enumerable
    # object. 
    def |(enum)
      assert_persisted

      tmp_key = ::UUIDTools::UUID.random_create.to_s

      # @todo error handling
      RedisGraph.connection.multi do
        enum.each { |value| RedisGraph.connection.sadd( tmp_key, value) }
        set = ::Set.new(send_command( :sunion, tmp_key ))
        RedisGraph.connection.del( tmp_key )
      end

      set
    end
    
    alias :union :|
    
    # Returns a new  set built by duplicating the set, removing every element that appears
    # in the given enumerable object. 
    def -(enum)
      assert_persisted

      tmp_key = ::UUIDTools::UUID.random_create.to_s

      # @todo error handling
      RedisGraph.connection.multi do
        enum.each { |value| RedisGraph.connection.sadd( tmp_key, value) }
        set = ::Set.new(send_command( :sdiff, tmp_key ))
        RedisGraph.connection.del( tmp_key )
      end

      set
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
      # Retrieve a Counter for +element+ by it's +name+, if no Counter can be found it 
      # creates new one with it's value set to 0.
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
        self.new(name, element, RedisGraph.connection.smembers( element.redis_key(name) ))
      end

      # This is the same as #get, except that it raises a NoFoundError exception
      # instead of returning nil, if no Element is found.
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
      # @raise [NotFoundError]
      #   The Element was not found
      # 
      # @api public
      def get!(element, key)
        get(key) || raise(NotFoundError, "A Set with the key of \"#{key.to_s}\" could not be found.")
      end
    end
    
    private
    
    def send_command(command, *args)
      @element.send_command( @name, command, *args )
    end
    
    def default
      ::Set.new
    end
    
    # A guard against writing extended data about an element before the main hash is written.
    def assert_persisted
      # I'd rather this was in the sets plugin than here...bah!
      unless @element.persisted?
        raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify a set until after an element is persisted."
      end
    end
  end # class Counter

  module Element
    module Plugins
      module Sets
        Model.add_extensions self

        def self.extended(model)
          model.send(:include, InstanceMethods)
        end

        module InstanceMethods
          protected

          # All sets for this element
          #
          # @return [Hash<Counter>]
          #   the Hash of sets for this element.
          #
          # @api private          
          def sets
            @sets ||= {}
          end

          # Reads the value of the Set called +name+.
          #
          # @param [#to_sym] name
          #     The name of the Set value to read.
          #
          # @return [Any]
          #   +value+
          #
          # @api private          
          def read_set(name)
            set = if sets.include?(name.to_sym)
                    sets[name.to_sym]
                  else
                    # If it hasn't been loaded yet, do so...
                    sets[name.to_sym] = Set.get( self, name )
                  end
            
            set
          end

          # Writes +value+ to the Set called +name+
          #
          # @param [#to_sym] name
          #     The name of the Set value to write to.
          #
          # @param [Any] value
          #     The value to assign to Set called +name+.
          #
          # @return [Any]
          #   +value+
          #
          # @api private
          def write_set(name, value)
            set = read_set(name)
            set.replace(value)
          end

        end # module InstanceMethods

        # Declare a Set called +name+ for this element.
        #
        # @param [Symbol, #to_sym] name
        #   The name of the new Set.
        # @param [Hash(Symbol => String)] options
        #   A hash of available options
        #
        # @return [Symbol]
        #   the set name
        #
        # @api public
        def set(name, options = {})
          set_name = name.to_sym

          # @todo we need to validate all extended attribute names against each other

          if sets.include?(set_name)
            raise NameInUseError, "A Set called '#{name.to_s}' has already been defined for #{self.inspect}."
          end

          sets << set_name

          create_set_reader(set_name, options)
          create_set_writer(set_name, options)
          
          set_name
        end

        # All sets declared for this element
        #
        # @return [Set<Symbol>]
        #   a Set of Symbols, representing the names of the sets for this element
        #
        # @api public
        def sets
          @sets ||= ::Set.new
        end

        private

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_set_reader(set_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:reader_visibility] || 'public'}
            def #{set_name.to_s}
              read_set(:#{set_name.to_s})
            end
          EOS
        end

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_set_writer(set_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:writer_visibility] || 'public'}
            def #{set_name.to_s}=(value)
              write_set(:#{set_name.to_s}, value)
            end
          EOS
        end
      end # module Sets
    end # module Plugins
  end # module Element
end # module RedisGraph