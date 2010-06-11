module RedisGraph
  module Relationships
    # @todo mimic enumerable
    class Has < Base
      include Enumerable

      # 
      # If a relationship has no metadata then it will be model with a set of keys of other nodes. (has n, :users)
      # If a relationship has metadata, then each relationship will have it's own has of metadata and a pointer to the other node. (has n, :leads, :for => :companies)
      # If a relationship can have any type of Node, then the syntax will be (has n, :assets, :model => :any or has n, :assets, :for => :meta, :model => :any)
      #
      # 
      #
      def initialize(node, name, raw, options = {})
        super(node, name, raw, options)

        @nodes = []
        @edges = []

        #@cardinality = cardinality
        # 
        
        if options.include?(:for)
          # @todo assert through is a valid edge
          @for_klass = options[:for]
        end

      end
      
      def each
        @nodes.each {|n| yield(n) }
      end
      
      def <=>(other)
        
      end

      # add an edge to this relationship
      def <<(edge)
        # @todo assert that we are within the bounds of cardinality
      end

      def save
        
      end

      def save!

      end

      def dirty?

      end
      
      def include?(name)
        
      end

      # @api private
      def load!
        @nodes = RedisGraph.key( @node.redis_key, @name )

        unless @for_klass == nil
          @edges = RedisGraph.key( @node.redis_key, @name, 'edges' )
        end
      end

      protected

      def store_raw
        # TODO: There must be a better way of doing this...
        old_members = @node.send_command( @name, :smembers )

        members_to_add = @raw

        # Remove any values that were in the set before, but aren't now
        unless old_members.empty?
          old_members = ::Set.new(old_members)

          ( old_members - @raw ).each do |v|
            @node.send_command( @name, :sremove, v )
          end
          
          members_to_add = members_to_add - old_members
        else
          members_to_add.each do |v|
            @node.send_command( @name, :sadd, v )
          end
        end
      end
    end # class Has
  end # module Relationships
end # module RedisGraph