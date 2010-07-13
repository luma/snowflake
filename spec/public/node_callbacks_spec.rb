require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Node do
  describe "callbacks" do
    class TestNodeWithCallbacks
      include RedisGraph::Node

      attribute :name,         String, :key => true
      attribute :age,          Integer
      attribute :mood,         String
      attribute :description,  String

      validates_presence_of :name
      
      attr_reader :callbacks
      
      def initialize(attributes = {})
        super(attributes)
        @callbacks = []
      end
      
      before_save "@callbacks << :before_save"
      after_save "@callbacks << :after_save"
      
      before_create "@callbacks << :before_create"
      after_create "@callbacks << :after_create"
      
      before_update "@callbacks << :before_update"
      after_update "@callbacks << :after_update"

      before_destroy "@callbacks << :before_destroy"
      after_destroy "@callbacks << :after_destroy"
      
      before_rename "@callbacks << :before_rename"
      after_rename "@callbacks << :after_rename"
    end
    
    before(:all) do
      @test_callback_node = TestNodeWithCallbacks.create(:name => 'rolly', :mood => 'Awesome')
    end
    
    describe "Save" do    
      it "triggers the before_save callback" do
        @test_callback_node.callbacks.should include(:before_save)
      end

      it "triggers the after_save callback" do
        @test_callback_node.callbacks.should include(:after_save)
      end
    end

    describe "Create" do
      it "triggers the before_create callback" do
        @test_callback_node.callbacks.should include(:before_create)
      end

      it "triggers the after_create callback" do
        @test_callback_node.callbacks.should include(:after_create)
      end
    end

    describe "Update" do
      before :all do
        @test_callback_node.age = 100
        @test_callback_node.save.should be_true
      end

      it "triggers the before_update callback" do
        @test_callback_node.callbacks.should include(:before_update)
      end

      it "triggers the after_update callback" do
        @test_callback_node.callbacks.should include(:after_update)
      end
    end

    describe "Rename" do
      before :all do
        @test_callback_node.key = 'bob'
        @test_callback_node.save.should be_true
      end

      it "triggers the before_rename callback" do
        @test_callback_node.callbacks.should include(:before_rename)
      end

      it "triggers the after_rename callback" do
        @test_callback_node.callbacks.should include(:after_rename)
      end
    end

    describe "Destroy" do
      before(:all) do
        @test_callback_node.destroy!.should be_true
      end

      it "triggers the before_destroy callback" do
        @test_callback_node.callbacks.should include(:before_destroy)
      end

      it "triggers the after_destroy callback" do
        @test_callback_node.callbacks.should include(:after_destroy)
      end
    end
  end

end
