module Snowflake
  module Plugins
    module Serialisers
      Model.add_inclusions ActiveModel::Serializers::JSON, ActiveModel::Serializers::Xml, self
      
      def serializable_hash(options = nil)
        options ||= {}

        hash = super(options)

        self.class.custom_attributes.each do |custom_attribute_name|
          hash[custom_attribute_name.to_s] = send(custom_attribute_name).serialise
        end

        hash
      end
    end # module Serialisers
  end # module Plugins
end # module Snowflake