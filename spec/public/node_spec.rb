require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Node do
  before(:all) do
    @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
  end

  describe "#get" do
    it "returns a Node by it's ID" do
      TestNode.get('rolly').should_not be_nil
    end

    it "returns nil when getting a Node that doesn't exist" do
      TestNode.get('figs!').should be_nil
    end
  end

  describe "#get!" do
    it "returns a Node by it's ID" do
      TestNode.get('rolly').should_not be_nil
    end
    
    it "raises an RedisGraph::NodeNotFoundError exception when getting a Node that doesn't exist" do
      lambda {
        TestNode.get!('figs!')
      }.should raise_error(RedisGraph::NodeNotFoundError)
    end
  end

  describe "#saved?" do
    it "indicates when a Node has been saved" do
      @test_node.should be_saved
    end
    
    it "indicates when a Node has not been saved" do
      TestNode.new.should_not be_saved
    end
  end
  
  describe "#save" do
    it "should save the Node" do
      TestNode.get('rolly').should_not be_nil
    end

    it "should update an existing node" do
      @test_node.description = "A Test Node"
      @test_node.save.should be_true
    end
  end
  
  describe "properties" do
    
  end

end
