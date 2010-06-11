module RedisGraph
  module Relationships
    class BelongsTo < Base
      def initialize(node, name, raw, options = {})
        super(node, name, raw, options)
      end
      
      def enumerable?
        false
      end
    end # class BelongsTo
  end # module Relationships
end # module RedisGraph