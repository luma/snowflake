require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Node do
  describe "Observers" do
    class FooNode
      include RedisGraph::Node
      include ActiveModel::Observing

      property :name,         String, :key => true
      property :age,          Integer
      property :mood,         String
      property :description,  String

      validates_presence_of :name
      
      after_save do
        notify_observers(:after_save)
      end
      
      attr_reader :observed_callbacks

      def initialize(attributes = {})
        super(attributes)
        @observed_callbacks = []
      end
    end

    class FooObserver < ActiveModel::Observer
      observe FooNode
      
      def after_save(foo_node)
        debugger
        puts "AFTER SAVE CALLBACK"
        foo_node.observed_callbacks << :foo_observer
      end
    end
    FooNode.observers = :foo_observer

    before(:all) do
      @test_foo = FooNode.create(:name => 'rolly', :mood => 'Awesome')
    end
    
    it "triggers an observer" do
      @test_foo.observed_callbacks.should include(:foo_observer)
    end

  end
end
