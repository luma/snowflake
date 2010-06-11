module RedisGraph
  module Relationships
    class Base
      attr_reader :node, :name, :options
      def initialize(node, name, raw, options = {})
        @node = node
        @name = name
        @options = options
        @raw = raw
      end
      
      def enumerable?
        true
      end

      def save

      end

      def save!

      end

      def dirty?

      end
    end # class Base
  end # module Relationships
end # module RedisGraph