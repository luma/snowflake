module RedisGraph
  # The Relationship base class
  #
  # @todo typecast?
  class Relationship
    attr_reader :name, :type, :options, :reader_visibility, :writer_visibility, :instance_variable_name

    def initialize(name, type, options = {})      
      @name = name
      @type = type
      @options = options

      # Assert @type
      if class_for_type == nil
        raise InvalidRelationshipType, "'#{@name.to_s}' has a type of '#{@type}', which is not a valid Relationship type."
      end

      @reader_visibility = options.delete(:reader_visibility) || 'public'
      @writer_visibility = options.delete(:writer_visibility) || 'public'

      @instance_variable_name = self.class.instance_variable_name(@name)
    end

    # Indicates the instance variable name that the Relationship will use within a Node.
    #
    # @return [String]
    #     The instance variable name
    #
    # @api private
    def self.instance_variable_name(name)
      "@#{name}".freeze
    end

    # Retrieve this relationship for +node+
    #
    # @param [Node] node
    #   The Node that we want to retrieve the Relationship for.
    #
    # @return [Relationships::Base, nil]
    #   The Relationship, or nil if non exists
    #
    # @api public
    def get(node)
      klass = class_for_type
      klass != nil ? klass.new(node, @name, nil, @options) : nil
    end

    # Retrieves a value from Redis by it's Key, the retrieval method used depends on the
    # Relationship's type.
    #
    # @todo This is a bit of a kludge right now. I'd rather this method wasn't necessary at all.
    #
    # @param [#to_s] key
    #     The Relationship key to retrieve
    #
    # @return [Various, nil]
    #     The Property value
    #
    # @api semi public
    def value_for_key( node_key )
      klass = class_for_type
      klass != nil ? klass.get( node_key, @name ) : nil
    end

    private

    def class_for_type
      begin
        Relationships.const_get(@type)
      rescue NameError => e
        nil
      end
    end
  end # class Relationship
end # module RedisGraph