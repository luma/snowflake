module RedisGraph
  class Counter
    attr_reader :name, :element

    def initialize(name, element, raw_counter = default)
      @name = name
      @element = element
      @raw = raw_counter.to_i
    end
    
    def to_i
      @raw
    end
    alias :to_int :to_i

    # Set the raw value of the Counter to +raw+. The new value is immediately persisted.
    #
    # @param [Integer, #to_i] raw
    #     The new value of the Counter.
    #
    # @return [Counter]
    #   self
    #
    # @api private
    def replace(raw)
      assert_persisted

      # I'd rather this was in the counters plugin than here...bah!
      unless @element.persisted?
        raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify a counter until after an element is persisted."
      end

      @raw =  unless raw.nil?
                raw.to_i
              else
                default
              end

      send_command( :set, @raw )

      self
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
    def incriment!(by = 1)
      assert_persisted

      # I'd rather this was in the counters plugin than here...bah!
      unless @element.persisted?
        raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify a counter until after an element is persisted."
      end

      @raw = send_command( :incrby, by.to_i )
    end
    alias :incr! :incriment!

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
    def decriment!(by = 1)
      assert_persisted

      # I'd rather this was in the counters plugin than here...bah!
      unless @element.persisted?
        raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify a counter until after an element is persisted."
      end

      @raw = send_command( :decrby, by.to_i )
    end
    alias :decr! :decriment!


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
        counter = RedisGraph.connection.get( element.redis_key(name) )

        # Counters default to zero
        # counter = 0 if counter.blank?

        self.new(name, element, counter)
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
        get(key) || raise(NotFoundError, "A Counter with the key of \"#{key.to_s}\" could not be found.")
      end
    end

    private
    
    def send_command(command, *args)
      @element.send_command( @name, command, *args )
    end
    
    def default
      0
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
      module Counters
        Model.add_extensions self

        def self.extended(model)
          model.send(:include, InstanceMethods)
        end

        module InstanceMethods
          protected

          # All counters for this element
          #
          # @return [Hash<Counter>]
          #   the Hash of Counters for this element.
          #
          # @api private          
          def counters
            @counters ||= {}
          end

          # Reads the value of the Counter called +name+.
          #
          # @param [#to_sym] name
          #     The name of the Counter value to read.
          #
          # @return [Any]
          #   +value+
          #
          # @api private          
          def read_counter(name)
            counter = if counters.include?(name.to_sym)
                        counters[name.to_sym]
                      else
                        # If it hasn't been loaded yet, do so...
                        counters[name.to_sym] = Counter.get( self, name )
                      end
            
            counter
          end

          # Writes +value+ to the Counter called +name+
          #
          # @param [#to_sym] name
          #     The name of the Counter value to write to.
          #
          # @param [Any] value
          #     The value to assign to Counter called +name+.
          #
          # @return [Any]
          #   +value+
          #
          # @api private
          def write_counter(name, value)
            counter = read_counter(name)
            counter.replace(value)
          end

        end # module InstanceMethods

        # Declare a Counter called +name+ for this element.
        #
        # @param [Symbol, #to_sym] name
        #   The name of the new Counter.
        # @param [Hash(Symbol => String)] options
        #   A hash of available options
        #
        # @return [Symbol]
        #   the counter name
        #
        # @api public
        def counter(name, options = {})
          counter_name = name.to_sym

          # @todo we need to validate all extended attribute names against each other

          if counters.include?(counter_name)
            raise NameInUseError, "A Counter called '#{name.to_s}' has already been defined for #{self.inspect}."
          end

          counters << counter_name

          create_counter_reader(counter_name, options)
          create_counter_writer(counter_name, options)
          
          counter_name
        end

        # All counters declared for this element
        #
        # @return [Set<Symbol>]
        #   a Set of Symbols, representing the counter names for this element
        #
        # @api public
        def counters
          @counters ||= ::Set.new
        end
        
        private

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_counter_reader(counter_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:reader_visibility] || 'public'}
            def #{counter_name.to_s}
              read_counter(:#{counter_name.to_s})
            end
          EOS
        end

        # @todo prevent these from being defined if they have already been defined somewhere else
        def create_counter_writer(counter_name, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            #{options[:writer_visibility] || 'public'}
            def #{counter_name.to_s}=(value)
              write_counter(:#{counter_name.to_s}, value)
            end
          EOS
        end
      end # module Counters
    end # module Plugins
  end # module Element
end # module RedisGraph