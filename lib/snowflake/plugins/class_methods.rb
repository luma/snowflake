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
      node.update_key_with_renaming( key )
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
    # def get_many(keys)
    #   hashes = Snowflake.connection.multi do
    #     keys.each do |key|
    #       Snowflake.connection.hgetall( key_for(key) )
    #     end
    #   end
    # 
    #   # @todo error check
    #   i = 0
    #   hashes.collect do |attributes|
    #     unless attributes == nil
    #       # @todo Deal with extended properties that aren't part of the hash: Maybe lazy load them?
    # 
    #       # We use #allocate, rather than #new, as we use #new to mean a Element that has not yet been
    #       # saved in the DB.
    #       node = self.allocate
    #       node.update_key_with_renaming( keys[i] )
    #       node.attributes = attributes
    #       node.reset!
    #       
    #       i++ 
    #       node
    #     else
    #       i++ 
    #       nil
    #     end        
    #   end.compact
    # end

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

    # Retrieve a random Element. It returns nil, if no Element is found.
    #
    # @return [Element, []]
    #   A random Element
    #   If there are no Elements
    # 
    # @api public
    def random (options = {})
      all( options ).random
    end
    
    def first(options = {})
      all( options ).first
    end

    def last(options = {})
      all( options ).last
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
    	# @todo extract pagination and limits from attribute filters

    	results = if options.empty?
              		Queries::Collection.new( self, Queries::Operand.new( self, 'all' ) )
              	else
                  filters = Queries::Operand.from_options( self, options )

                  # If we've got more than one filter then we'll AND them together. If there's
                  # only one we just use the Operand directly.
                  operand = if filters.length > 1
                              Queries::Operations::AndOperation.new( *filters )
                            else
                              filters.first
                            end

                  Queries::Collection.new( self, operand )
              	end

    	# @todo paginate and limit the result

    	# At this point the results collection holds the operation, but has not actually executed 
    	# anything against the datastore yet	
    	results
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
    # README: This method is a little dangerous, right now. It doesn't trigger an index
    #         generating event. So if you want the indices to be updated you'll need to
    #         manually broadcast the event after calling this, or use the destroy method
    #         on an Element instance (which *does* broadcasts events).
    #         
    #         This will be fixed when I get a chance to refactor.
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
      full_from_key = key_for(from_key)
      full_to_key = key_for(to_key)

      # results = Snowflake.connection.multi do |conn|
        Snowflake.connection.renamenx( full_from_key, full_to_key )

        Snowflake.connection.srem( meta_key_for( 'indices', 'all' ), full_from_key )
        Snowflake.connection.sadd( meta_key_for( 'indices', 'all' ), full_to_key )
        
        # @todo provide a hook to allow extended attributes to be moved
      # end

      # @todo error handling    
      # @todo move indices     

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
    # README: This method is a little dangerous, right now. It doesn't trigger an index
    #         generating event. So if you want the indices to be updated you'll need to
    #         manually broadcast the event after calling this, or use the destroy method
    #         on an Element instance (which *does* broadcasts events).
    #         
    #         This will be fixed when I get a chance to refactor.
    #
    # @return [Boolean]
    #     True for sucess, false otherise.
    #
    # @api public      
    def destroy!( key )
      full_key = key_for(key)

      results = Snowflake.connection.multi do |conn|
        conn.del( full_key )
        conn.srem( meta_key_for( 'indices', 'all' ), full_key )
      end

      # @todo error handling
      # @todo broadcast destroy event to indexer

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

    def broadcast_event_to_listeners(event, key, payload)
      @listener ||= ::Snowflake::Listener.new
      @listener.broadcast(event, key, payload)
    end
  end # module ClassMethods
end # module Snowflake