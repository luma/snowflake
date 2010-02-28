module RedisGraph
  module Node
    extend ::MongoMapper::Support::DescendantAppends
    
    def initialize(properties = {})
      self.id = properties.delete(:id)
      self.properties = properties
    end
    
    def id
      instance_variable_get(:@id)
    end
    
    def save
      IdentityMap[full_id] = properties
    end

    def self.included(model)
      model.extend(ClassMethods)
    end

    module ClassMethods
      extend DataMapper::Chainable

      def self.extended(model)
        #model.instance_variable_set(:@descendants, descendants.class.new( descendants.to_a ))
      end

      chainable do
        def inherited(model)
          extra_extensions.each { |extension| model.extend(extension) }
          extra_inclusions.each { |inclusion| model.send(:include, inclusion) }
          descendants << model
          #model.instance_variable_set(:@descendants, descendants.class.new( descendants.to_a ))

          super
        end
      end
      
      def get(id)
        node = IdentityMap[partial_to_full_id(id)]
        new(node.merge(:id => id))
      end

      protected

      def partial_to_full_id(id)
        [self.to_s, id].join(":")
      end
    end

    protected

    def id=(id)
      instance_variable_set(:@id, id)
    end

    private
    
    def full_id
      [self.class.to_s, self.id].join(":")
    end
  end # module Node
end # module RedisGraph