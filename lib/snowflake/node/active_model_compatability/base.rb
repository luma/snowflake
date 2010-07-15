

module Snowflake
  module Node
    module ActiveModelCompatability
      # Provides basic compatability with ActiveModel
      # @usage include Snowflake::Node::ActiveModelCompatability::Base
      module Base
        def to_model
          self
        end
        
        # Indicates whether this Node has been saved yet. Synonym of #new?
        #
        # @return [Boolean]
        #   True if this Node has been saved, false otherwise.
        #
        # @api public
        def new_record?
          self.new?
        end
        
        # Retrieve the value of the key property for this Node. Synonym of #key.
        #
        # @return [#to_s] The Id value
        #
        # @api public
        def to_key
          key
        end
      end # module Validations
    end # module ActiveModelCompatability
  end # module Node
end # module Snowflake