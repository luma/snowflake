module Snowflake
  module Keys
    class << self
      
      # @todo validate key segments
      
      # Construct a key for this element from +segments+.
      #
      # @todo I'm not thrilled about this being public, it needs to be public right now as instances of Element use it
      #
      # @api public
      def key_for( object, *segments )
        segments.unshift(object.to_s).join(':')
      end

      # Construct a meta key for this element from +segments+.
      #
      # @api public
      def meta_key_for( object, *segments )
        segments.unshift(object.to_s).join('::')
      end

      # Construct an element key from +segments+.
      #
      # @api public
      def key(*segments)
        segments.join(':')
      end

      # Construct a meta key (for storing metainfo regarding elements) for +segments+.
      #
      # @api public
      def meta_key(*segments)
        segments.join('::')
      end

    end
  end # module Keys
end # module Snowflake