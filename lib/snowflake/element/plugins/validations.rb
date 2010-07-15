module Snowflake
  module Element
    module Plugins
      module Validations
#        Model.add_extensions ActiveModel::Validations, self
        Model.add_inclusions ActiveModel::Validations, self

        # Reads the value of the Property called +name+.
        #
        # The validations system calls read_attribute_for_validation to get the attribute, but by default, 
        # it aliases that method to send, which supports the standard Ruby attribute system of attr_accessor.
        # 
        # Rather than using send, which calls read_attribute anyway, we going to call it directly.
        #
        # @param [#to_sym] name
        #     The name of the Property value to read
        #
        # @return [Any]
        def read_attribute_for_validation(key)
          read_attribute(key)
        end

      end # module Validations
    end # module Plugins
  end # module Element
end # module Snowflake