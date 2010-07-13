module RedisGraph
  module Element
    module Plugins
      module Serialisers
        Model.add_inclusions ActiveModel::Serializers::JSON, ActiveModel::Serializers::Xml
      end # module Serialisers
    end # module Plugins
  end # module Element
end # module RedisGraph