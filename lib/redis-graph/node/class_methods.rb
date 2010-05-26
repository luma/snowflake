module RedisGraph
  module Node
    module ClassMethods
      # @api public
      def get(id)
        node = RedisGraph.connection.hgetall( redis_key(id) )
        return false if node == nil

        # Deal with extended properties that aren't part of the hash
        non_hash_properties.each do |name|
          property = properties[name]
          node[name.to_sym] = property.value_for_key(redis_key(id, name))
        end

        new(node.merge(:id => id))
      end

      # @api public
      def get!(id)
        node = get(id)

        unless node
          raise NodeNotFoundError.new("A #{self.to_s} with the id of \"#{id.to_s}\" could not be found.")
        end

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