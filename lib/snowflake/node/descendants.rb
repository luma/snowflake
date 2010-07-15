module Snowflake
  module Node
    module Descendants
      # Retrieves the list of all descendants of this Node
      #
      # @return [Array]
      #   the list of descendants
      #
      # @api public
      def descendants
        @descendants ||= Set.new
      end
      
    end # module Descendants
  end # module Node
end # module Snowflake