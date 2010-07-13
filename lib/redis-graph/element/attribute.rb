module RedisGraph
  # The Attribute base class
  #
  # @todo typecast?
  class Attribute
    attr_accessor :name
    attr_reader :node, :options, :reader_visibility, :writer_visibility

    def initialize(node, name, options = {})
      @node = node
      @name = name.to_sym
      @options = options

      @key = options.include?(:key) && options[:key] == true

      # 'key' is a restricted attribute name, you can use it but you must set :key => true 
      # as well. We could implictly set :key => true but I'd rather make users aware of
      # a potential problem when defining their models, rather than have them trip over
      # it later as an obscure bug.
      if @name == :key && !@key
        raise ArgumentError, "Attributes called 'key' must also set the :key option to true, did you forget to set the :key option?"
      end

      # We only check if the key name is not 'key'. If it is called 'key', and it wasn't 
      # rejected by previous checks, it's definately a valid attribute name so we can
      # skip the next check.
      if @name != :key && self.class.restricted_names.include?(@name)
        raise ArgumentError, "'#{@name}' is a restricted attribute name, it cannot be used. The following are all restricted attribute names: #{self.class.restricted_names.join(', ')}"
      end

      @reader_visibility = options.delete(:reader_visibility) || 'public'
      @writer_visibility = options.delete(:writer_visibility) || 'public'
    end

    # Returns the default value for this Attribute.
    #
    # @return [Any]
    #     The default value.
    #
    # @api public
    def default
      if options[:default].respond_to?(:call)
        options[:default].call(@node, self)
      else
        options[:default]
      end
    end

    # Indicates whether this Attribute represents an element key
    #
    # @return [Boolean]
    #     True, if this Attribute is an element key, false otherwise.
    #
    # @api public
    def key?
      @key
    end

    # Indicates whether this Attribute represents a primitive ruby type 
    #
    # @return [Boolean]
    #     True if this Attribute represents a primitive.
    #
    # @api public
    def primitive?
      self.class.primitive?
    end

    # Typecasts +value+ to the correct type for this Attribute.
    #
    # @param [Any] value
    #     The value to convert.
    #
    # @return [Any]
    #     A typecast version of +value+.
    # 
    # @api semi-public
    def typecast(value)
      raise NotImplemented, "Valid Attributes have to subclass the Attribute Class and implement the 'typecast' method."
    end

    def self.inherited(child)
      child.extend AttributeClassMethods
    end

    # Retrieves a Hash of alternate names for all Attribute types.
    #
    # @return [Hash]
    #   a Hash of all aliases
    #
    # @api public
    def self.aliases
      @aliases ||= {}
    end
    
    # The list of restricted attribute names. This list could be huge, we just specify
    # several of the most damaging ones here and leave the rest to common sense...which
    # could be a terrible error.
    #
    # @return [Array<Symbol>]
    #     An array of Symbols representing restricted attribute names.
    #
    # @api semi-public
    def self.restricted_names
      [:key, :class, :send, :inspect].freeze
    end
    
    def self.restricted_name?(name)
      restricted_names.include?(name.to_sym)
    end

    # Retrieves a Attribute by it's +type+. This also handles Attribute primitive names, so
    # TrueClass will map to Properties::Boolean.
    #
    # @param [String, #to_s] type
    #     The type name of the Attribute.
    #
    # @return [Attribute, nil]
    #     The object for the desired +type+, or nil if +type+ does not map to a valid Attribute.
    #
    # @api semi-public
    def self.get(type)
      demodulised_type = type.to_s.demodulize
      non_primitive_name = aliases[demodulised_type] || demodulised_type

      begin
        RedisGraph::Attributes.const_get(non_primitive_name)
      rescue NameError => e
        nil
      end
    end

    module AttributeClassMethods
      # Retrieves the Set of alternate names of this Attribute type. These are **not**
      # inherited.
      #
      # @todo Should these be inherited?
      #
      # @return [Set]
      #   the Set of all alternate names for this Attribute type
      #
      # @api public
      def aliases
        @aliases ||= ::Set.new
      end

      # Adds one or more new aliases to the list of aliases for this Attribute type.
      #
      # @param [Enumerable] *aliases
      #     One or more aliases.
      #
      # @return [Set]
      #   the list of aliases
      #
      # @api public
      def alias_for(*aliases)
        # Look for any aliases that are already in use.
        overlapped_names = ::Set.new(Attribute.aliases.keys) & aliases
        unless overlapped_names.empty?
          readable_names = overlapped_names.collect do |name|
            "#{name} (#{Attribute.aliases[name].to_s})"
          end

          raise AliasInUseError, "The following aliases were already in use: #{readable_names}."
        end

        # Register these aliases as belonging to this Attribute Type
        aliases.each do |a|
          Attribute.aliases[a.to_s] = self.name.demodulize
        end

        self.aliases.merge(aliases)
      end

      # Indicates whether this Attribute is a primitive. Primitives are internal proxy
      # classes that represent (and decorate) existing Ruby classes. One example of a
      # primitive would be String.These are **not**
      # inherited.
      #
      # Attributes are *not* primitives by default.
      #
      # @todo Should these be inherited?
      #
      # @return [Boolean]
      #     True if the Attribute is a primitive, false otherwise
      #
      # @api public
      def primitive?
        @primitive ||= false
      end
      
      # Indicates whether this Attribute is a primitive.
      #
      # @param [Boolean] p
      #     Boolean to indicate whether this Attribute is a primitive or not.
      #
      # @api public
      def primitive(p)
        @primitive = p
      end

    end # module AttributeClassMethods
  end # class Attribute
end # module RedisGraph