module Snowflake
  module ClassMethods
    Model.add_extensions self

    # Retrieve a Element by it's +key+, it returns nil if no Element can be found.
    #
    # @param [#to_s] key
    #     The key of the Element that you wish to retrieve.
    #
    # @return [Element, nil]
    #   A Element with the key of +key+
    #   If no Element was found with the key of +key+
    # 
    # @api public
    def get(key)
      node_attributes = Snowflake.connection.hgetall( key_for(key) )
      return nil if node_attributes.empty?

      # @todo Deal with extended properties that aren't part of the hash: Maybe lazy load them?

      # We use #allocate, rather than #new, as we use #new to mean a Element that has not yet been
      # saved in the DB.
      node = self.allocate
      node.key = key
      node.attributes = node_attributes

      node.reset!
      node
    end

    # Retrieve Elements by their +keys+, it returns [] if no Elements can be found.
    #
    # @param [Array<#to_s>] keys
    #     The array keys of the Elements that you wish to retrieve.
    #
    # @return [Element, []]
    #   A Element with the key of +key+
    #   If no Elements were found with any of +keys+
    # 
    # @api public
    def get_many(keys)
      keys.collect do |key|
        get(key)
      end.compact
    end

    # This is the same as #get, except that it raises a NotFoundError exception
    # instead of returning nil, if no Element is found.
    #
    # @param [#to_s] key
    #     The key of the Element that you wish to retrieve.
    #
    # @return [Element]
    #   A Element with the key of +key+
    #
    # @raise [NotFoundError]
    #   The Element was not found
    # 
    # @api public
    def get!(key)
      get(key) || raise(NotFoundError, "A #{self.to_s} with the key of \"#{key.to_s}\" could not be found.")
    end

    # Retrieve a collection of nodes based on +options+, if +options+ is omitted all
    # nodes will be returned.
    #
    # @param [Hash] options
    #     The parameters to filter the nodes by, if blank all nodes will be returns.
    #
    # @return [Collection]
    #     The Collection of nodes, filtered by +options+.
    #
    # @api public
    # @todo
    def all(options = {})
      # @todo deal with options

      indices[:all].all
    end

    # Indicates whether a Element exists for key +key+.
    #
    # @param [#to_s] key
    #     The key to test for.
    #
    # @return [Boolean]
    #     True if a Element exists for key +key+, false otherwise.
    #
    # @api public
    def exists?(key)
      Snowflake.connection.exists( key_for(key) )
    end
    
    # Rename an Element from +from_key+ to +to_key+.
    #
    # @param [#to_s] from_key
    #     The key of the Element that we are moving.
    #
    # @param [#to_s] to_key
    #     The key to move the Element to.
    #
    # @return [Boolean]
    #     True if the move was sucessful, false otherwise.
    #
    # @api public
    def rename(from_key, to_key)
      Snowflake.connection.renamenx( key_for(from_key), key_for(to_key) )
      # @todo provide a hook to allow extended attributes to be moved
      
      # @todo error handling
      true
    end

    # Creates a new Element using +options+. You can also provide a block to specialise the Element
    # before it is saved.
    #
    # @param [Hash] options
    #     Optional Hash of options to create the Element with.
    #
    # @return [Element]
    #     The new Element.
    # 
    # @api public
    def create( options = {} )
      node = self.new(options)
      yield node if block_given?
      node.save
      node
    end

    # Deletes the Element by its key. This does not trigger any callbacks, if you need
    # to trigger callbacks use: Model.get(key).destroy!
    #
    # @return [Boolean]
    #     True for sucess, false otherise.
    #
    # @api public      
    def destroy!( key )
#        raise NotImplementedError, 'Modules that include Snowflake::Element must implement a destroy! method.'
      # @todo error handling
      Snowflake.connection.del( key_for(key) )

      true
    end

#      protected

    # Construct a key for this element from +segments+.
    #
    # @todo I'm not thrilled about this being public, it needs to be public right now as instances of Element use it
    #
    # @api semi-public
    def key_for( *segments )
      Keys.key_for( self, *segments )
    end

    # Construct a meta key for this element from +segments+.
    #
    # @api semi-public
    def meta_key_for( *segments )
      Keys.meta_key_for( self, *segments )
    end

  end # module ClassMethods
end # module Snowflake