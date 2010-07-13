module RedisGraph
  class PropertyPrototype
    attr_accessor :name, :type, :reader_visibility, :writer_visibility
    attr_reader :node_class, :instance_variable_name, :options

    def initialize(node_class, name, type, options = {})
      if Property.get(type) == nil
        raise ArgumentError, "An invalid type, '#{type.to_s}', was specified for Property '#{name.to_s}'."
      end

      @node_class = node_class
      @name = name
      @type = type
      @options = options

      @reader_visibility = options.delete(:reader_visibility) || 'public'
      @writer_visibility = options.delete(:writer_visibility) || 'public'

      @key = options.include?(:key) && options[:key] == true
      @instance_variable_name = Property.instance_variable_name(@name)
    end
    
    # Creates a new Property instance for the Node +node+ based on this PropertyPrototype.
    #
    # @param [Node] node
    #     The Node that the new Property will be instanciated for.
    #
    # @return [Property, nil]
    #     A Property, based on this PropertyPrototype, for +node+ and +type+, or nil if +type+ was invalid.
    #
    # @api semi-public
    def to_property(node)
     klass = property_class_for_type
     klass != nil klass.new(node, @name, nil, @options) : nil
    end

    # Retrieves the Property class represented by this PropertyPrototype type attribute.
    #
    # @return [Property Class, nil]
    #     The Property class for +@type+, or nil if +type+ does not map to a valid Property.
    #
    # @api semi-public
    def property_class_for_type
      Property.get(@type)
    end
    
    # Indicates whether this PropertyPrototype represents a Property that stands in for
    # a Ruby primitive.
    #
    # @return [Boolean]
    #     True if the Property that this represents is a primitive, false otherwise.
    #
    # @api public
    def primitive?
      property_class_for_type.primitive?
    end

    # Indicates whether this is also should be the key field.
    #
    # @return [Boolean]
    #     True if this represents the key field, false otherwise.
    #
    # @api public
    def key?
      @key
    end

    # Indicates whether this Property is one of those that will be included in the main object hash
    #
    # @return [Boolean]
    #     True if this Property is part of the main object Hash, false otherwise.
    #
    # @api private
    def hash_property?
      [Properties::String, Properties::Boolean, Properties::Integer, Properties::Guid, Properties::Counter].include?(self.property_class_for_type)
    end

    # Retrieves a value from Redis by it's Key, the retrieval method used depends on the
    # Properties type.
    #
    # @todo This is a bit of a kludge right now. I'd rather this method wasn't necessary at all.
    #
    # @param [#to_s] key
    #     The Property key to retrieve
    #
    # @return [Various]
    #     The Property value
    #
    # @api semi public
    def value_for_key(key)
      # @todo Dude, this is fugly
      case @type.to_s
      when "RedisGraph::Properties::Set"
        RedisGraph.connection.smembers( key )
      when "RedisGraph::Properties::List"
        RedisGraph.connection.lrange( key, 0, -1 )
      when "RedisGraph::Properties::Hash"
        RedisGraph.connection.hgetall( key )
      else
        # When in doubt, assume a string
        RedisGraph.connection.get( key )
      end
    end

  end # class PropertyPrototype
end # module RedisGraph