module RedisGraph
  module Node
    module ClassMethods
      # Retrieve a Node by it's +key+, it returns nil if no Node can be found.
      #
      # @param [#to_s] key
      #     The key of the Node that you wish to retrieve.
      #
      # @return [Node, nil]
      #   A Node with the key of +key+
      #   If no Node was found with the key of +key+
      # 
      # @api public
      def get(key)
        node_properties = RedisGraph.connection.hgetall( redis_key(key) )
        return nil if node_properties.empty?

        # Deal with extended properties that aren't part of the hash
        non_hash_properties.each do |name|
          property = properties[name]
          node_properties[name.to_sym] = property.value_for_key(redis_key(key, name))
        end

        # We use #allocate, rather than #new, as we use #new to mean a Node that has not yet been
        # saved in the DB.
        node = self.allocate
        node.key = key
        node.properties = node_properties
        node.reset!
        node
      end

      # This is the same as #get, except that it raises a NodeNoFoundError exception
      # instead of returning nil, if no Node is found.
      #
      # @param [#to_s] key
      #     The key of the Node that you wish to retrieve.
      #
      # @return [Node]
      #   A Node with the key of +key+
      #
      # @raise [NodeNotFoundError]
      #   The Node was not found
      # 
      # @api public
      def get!(key)
        get(key) || raise(NodeNotFoundError, "A #{self.to_s} with the key of \"#{key.to_s}\" could not be found.")
      end

      # 
      # @api public
      def create(options = {})
        node = self.new(options)
        node.save
        node
      end

#      protected

      # @todo I'm not thrilled about this being public, it needs to be public right now as instances of Node use it
      # @api private
      def redis_key(*segments)
        segments.unshift(self.to_s).join(':')
      end
    end # module Descendants
  end # module Node
end # module RedisGraph