module Snowflake
  module Plugins
    module Serialisers
      Model.add_inclusions ActiveModel::Serializers::JSON, ActiveModel::Serializers::Xml
    end # module Serialisers
  end # module Plugins
end # module Snowflake