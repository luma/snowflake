module Snowflake
  # The Attribute base class
  #
  # @todo typecast?
  class CustomAttribute
    attr_reader :name, :element

    def initialize(name, element, raw = default)
      @name = name
      @element = element
      @raw = typecast(raw)
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
      raise NotImplemented, "Subclasses must implment #replace."
    end

    # Cast +value+ to whatever type @raw should be. Raise exceptions for invalid types.
    # @api semi-public
    def typecast(value)
      case value
      when nil
        default
      else
        value.to_s
      end
    rescue StandardError => e
      raise InvalidTypeError, "Cannot cast '#{value.inspect}' for #{self.inspect}. Original Error: #{e.message}."
    end

    def key
      @element.key_for( name )
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
        value = element.send_command( name, :get )
        self.new(name, element, value )
      end

      # This is the same as #get, except that it raises a NoFoundError exception
      # instead of returning nil, if no Element is found.
      #
      # @param [Element] element
      #     The Element, to find Counter +name+ for.
      # @param [String, #to_string] name
      #     The name of Counter we're looking for.
      #
      # @return [Element, nil]
      #   A Element with the key of +name+
      #   If no Element was found with the name of +name+
      #
      # @raise [NotFoundError]
      #   The Element was not found
      # 
      # @api public
      def get!(element, name)
        get(name) || raise(NotFoundError, "A #{name} with the name of \"#{name.to_s}\" could not be found.")
      end

      def name
        self.to_s.demodulize
      end
    end

    private
    
    def send_command(command, *args, &block)
      @element.send_command( @name, command, *args, &block )
    end
    
    def default
      raise NotImplemented, "Subclasses must implement #default."
    end
    
    # A guard against writing extended data about an element before the main hash is written.
    def assert_persisted
      # I'd rather this was in the sets plugin than here...bah!
      unless @element.persisted?
        raise NotPersisted, "#{@element.inspect} is not persisted, you cannot modify this #{self.class.name} until after it's parent element is persisted."
      end
    end
  end # class Attribute
end # module Snowflake