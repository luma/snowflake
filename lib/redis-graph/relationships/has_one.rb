module RedisGraph
  module Relationships
    class HasOne < Base
      # 
      # If a relationship has no metadata then it will be model with a set of keys of other nodes. (has n, :users)
      # If a relationship has metadata, then each relationship will have it's own has of metadata and a pointer to the other node. (has n, :leads, :for => :companies)
      # If a relationship can have any type of Node, then the syntax will be (has n, :assets, :model => :any or has n, :assets, :for => :meta, :model => :any)
      #
      def initialize(node, name, raw, options = {})
        super(node, name, raw, options)
        #@cardinality = cardinality
        
        #if options.include?(:for) 
        
      end
      
      # add an edge to this relationship
      def <<(edge)
      end
    end # class Has
  end # module Relationships
end # module RedisGraph