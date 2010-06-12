module RedisGraph
  # The Property base class
  #
  # @todo typecast?
  class Property
    attr_accessor :name
    attr_reader :node, :instance_variable_name, :options, :raw

    def initialize(node, name, raw_value, options = {})
      @node = node
      @name = name
      @options = options
      @dirty = false
      @raw = raw_value || default
      @saved = raw_value != nil
      @instance_variable_name = self.class.instance_variable_name(@name)
    end
    
    # Returns the default value for this Property.
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

    # Indicates whether this Property represents a primitive ruby type 
    #
    # @return [Boolean]
    #     True if this Property represents a primitive.
    #
    # @api public
    def primitive?
      self.class.primitive?
    end

    # Indicates whether this Property have been modified since the last save.
    #
    # @return [Boolean]
    #     True if changes have been made, false otherwise.
    #
    # @api public
    def dirty?
      @dirty
    end

    # Indicates whether this Property's raw value exists in Redis. This is different from #dirty? as
    # #dirty? indicates whether a new raw value has been assigned, whereas if #persisted? is false then
    # if you peeked at the value for this Property in Redis you would get nil.
    #
    # @return [Boolean]
    #     True if the raw value exists in Redis, false otherwise.
    #
    # @api public
    def persisted?
      @saved
    end
    
    # Clear our dirty tracking
    #
    # @api private
    def clean!
      @dirty = false
    end
    
    # Indicates whether this Property is one of those that will be included in the main object hash
    #
    # @return [Boolean]
    #     True if this Property is part of the main object Hash, false otherwise.
    #
    # @api private
    def hash_property?
      [::RedisGraph::Properties::String, ::RedisGraph::Properties::Boolean].include?(self.class)
    end

    # Make inspection of our properties a little prettier by actually inspectin' the raw value, for
    # more complex Property types, this method may need to be overwritten.
    #
    # @return [String]
    #
    # @api public
    def inspect
      @raw.inspect
    end

    # Assigns a raw value to this Property.
    #
    # @param [Any] raw
    #     The raw value to assign.
    #
    # @api public
    def raw=(raw)
      raise NotImplemented, "Valid Properties have to subclass the Property Class and implement the 'raw=' method."
    end

    # Writes the value of this Property to the Redis store.
    # 
    # @api semi-public
    def store!
      before_store
      store_raw
      after_store
    end
    
    def before_store
      
    end
    
    def after_store
      @dirty = false
      @saved = true
    end

    def self.inherited(child)
      child.extend Attributes
    end
    
    # Retrieves a Hash of alternate names for all Property types.
    #
    # @return [Hash]
    #   a Hash of all aliases
    #
    # @api public
    def self.aliases
      @aliases ||= {}
    end

    # Retrieves a Property by it's +type+. This also handles Property primitive names, so
    # TrueClass will map to Properties::Boolean.
    #
    # @param [String, #to_s] type
    #     The type name of the Property.
    #
    # @return [Property, nil]
    #     The object for the desired +type+, or nil if +type+ does not map to a valid Property.
    #
    # @api semi-public
    def self.get(type)
      demodulised_type = type.to_s.demodulize
      non_primitive_name = aliases[demodulised_type] || demodulised_type

      begin
        Properties.const_get(non_primitive_name)
      rescue NameError => e
        nil
      end
    end
    
    # Indicates the instance variable name that the Property will use within a Node.
    #
    # @return [String]
    #     The instance variable name
    #
    # @api private
    def self.instance_variable_name(name)
      "@#{name}".freeze
    end

    module Attributes
      # Retrieves the Set of alternate names of this Property type. These are **not**
      # inherited.
      #
      # @todo Should these be inherited?
      #
      # @return [Set]
      #   the Set of all alternate names for this Property type
      #
      # @api public
      def aliases
        @aliases ||= Set.new
      end

      # Adds one or more new aliases to the list of aliases for this Property type.
      #
      # @param [Enumerable] *aliases
      #     One or more aliases.
      #
      # @return [Set]
      #   the list of descendants
      #
      # @api public
      def alias_for(*aliases)
        # Look for any aliases that are already in use.
        overlapped_names = Set.new(Property.aliases.keys) & aliases
        unless overlapped_names.empty?
          readable_names = overlapped_names.collect do |name|
            "#{name} (#{Property.aliases[name].to_s})"
          end

          raise AliasInUseError, "The following aliases were already in use: #{readable_names}."
        end

        # Register these aliases as belonging to this Property Type
        aliases.each do |a|
          Property.aliases[a.to_s] = self.name.demodulize
        end

        self.aliases.merge(aliases)
      end

      # Indicates whether this Property is a primitive. Primitives are internal proxy
      # classes that represent (and decorate) existing Ruby classes. One example of a
      # primitive would be String.These are **not**
      # inherited.
      #
      # Properties are *not* primitives by default.
      #
      # @todo Should these be inherited?
      #
      # @return [Boolean]
      #     True if the Property is a primitive, false otherwise
      #
      # @api public
      def primitive?
        @primitive ||= false
      end
      
      # Indicates whether this Property is a primitive.
      #
      # @param [Boolean] p
      #     Boolean to indicate whether this Property is a primitive or not.
      #
      # @api public
      def primitive(p)
        @primitive = p
      end

    end # module Attributes

    protected
    
    # Writes the value of this Property to the Redis store.
    # 
    # @api semi-public
    def store_raw
      raise NotImplemented, "Valid Properties have to subclass the Property Class and implement the 'store' method."
    end

  end # class Property
end # module RedisGraph