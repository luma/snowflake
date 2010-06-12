module RedisGraph
  module Node
    module ActiveModelCompatability
      # Provides compatability with ActiveModel Validations
      # @usage include RedisGraph::Node::ActiveModelCompatability::Validations
      module Validations
        # Reads the value of the Property called +name+.
        #
        # The validations system calls read_attribute_for_validation to get the attribute, but by default, 
        # it aliases that method to send, which supports the standard Ruby attribute system of attr_accessor.
        # 
        # Rather than using send, which calls read_property anyway, we going to call it directly.
        #
        # @param [#to_sym] name
        #     The name of the Property value to read
        #
        # @return [Any]
        def read_attribute_for_validation(key)
          read_property(key)
        end
      end # module Validations
    end # module ActiveModelCompatability
  end # module Node
end # module RedisGraph