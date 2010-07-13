module RedisGraph
  module Element
    module Plugins
      module Hooks
        Model.add_extensions ActiveModel::Callbacks
        Model.add_inclusions self
      
        def self.included(model)
          model.class_eval do
            define_model_callbacks :create, :update, :save, :destroy, :rename
          end
        end
        
      end # module Hooks
    end # module Plugins
  end # module Element
end # module RedisGraph