require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  describe "Observers" do
    class FooNode
      include Snowflake::Node
      include ActiveModel::Observing

      attribute :name,         String, :key => true
      attribute :age,          Integer
      attribute :mood,         String
      attribute :description,  String

      validates_presence_of :name

      after_save do
        notify_observers(:after_save)
      end

      def self.observed_callbacks
        @observed_callbacks ||= []
      end

      def initialize(attributes = {})
        super(attributes)
        @observed_callbacks = []
      end
    end

    class FooObserver < ActiveModel::Observer
      observe FooNode
      
      def after_save(foo_node)
        FooNode.observed_callbacks << :foo_observer
      end
      
    end

    before(:all) do
      FooNode.observers = :foo_observer
      FooNode.instantiate_observers
      @test_foo = FooNode.create(:name => 'rolly', :mood => 'Awesome')
    end
    
    it "triggers an observer" do
      FooNode.observed_callbacks.should include(:foo_observer)
    end

  end
end
