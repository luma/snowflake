module Snowflake
  module Attributes
    # Retrieves a Attribute Class by +type+. This also handles Attribute primitive alias 
    # names, so TrueClass will map to Properties::Boolean.
    #
    # @param [String, #to_s] type
    #     The type name of the Attribute.
    #
    # @return [Attribute]
    #     The object for the desired +type+.
    #
    # @raise [ArgumentError]
    #     An Attribute Class called +type+ could not be found.
    #
    # @api semi-public
    def self.get(type)
      klass = Attribute.get(type)
      if klass == nil
        raise ArgumentError, "The '#{type.to_s}' attribute type could not be found."
      end

      klass
    end
  end # module Attributes
end # module Snowflake