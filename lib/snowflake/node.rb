module Snowflake
  module Node        
    def self.included(model)
      model.extend Model
    end
    include Element
  end # module Node
end # module Snowflake