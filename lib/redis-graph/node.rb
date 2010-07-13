module RedisGraph
  module Node        
    def self.included(model)
      model.extend Element::Model
    end
    include Element
  end # module Node
end # module RedisGraph