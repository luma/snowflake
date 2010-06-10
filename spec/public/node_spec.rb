require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Node do
  before(:each) do
    @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
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
    
    it "should rename all redis keys when modifying the node key" do
      @test_node.key = 'bob'
      @test_node.save
      TestNode.get('rolly').should be_nil
      TestNode.get('bob').should_not be_nil
    end
  end
  
  describe "equality" do
    describe "#==" do
      it "returns true when the two Nodes are the same" do
        @test_node.should == TestNode.get('rolly')
      end

      it "returns false when the two Nodes are not the same" do
        @test_node.should_not == TestNode.create(:name => 'bob', :mood => 'Awesome')
      end
    end

    describe "#eql?" do
      it "returns true when the two Nodes are the same" do
        @test_node.should eql(TestNode.get('rolly'))
      end

      it "returns false when the two Nodes are not the same" do
        @test_node.should_not eql(TestNode.create(:name => 'bob', :mood => 'Awesome'))
      end
    end

    describe "#equal?" do
      it "returns true when the two Node Objects are the same" do
        @test_node.should equal(@test_node)
      end

      it "returns false when the two Node Objects are not the same" do
        @test_node.should_not equal(TestNode.get('rolly'))
      end
    end
  end
  
  describe "validation" do
    # @todo add proper tests for this
    it "should not save when validation fails" do
      @test_node.name = nil
      @test_node.save.should be_false
      @test_node.errors.on(:name).should_not be_blank
    end
    
    it "should not save a new Node with a key that's identical to an existing one" do
      node = TestNode.new(:name => @test_node.name)
      node.save.should be_false
      node.errors.on(:name).should_not be_blank
    end
  end
  
  describe "#destroy!" do
    it "deletes a saved Node" do
      @test_node.destroy!.should be_true
      TestNode.get('rolly').should be_nil
    end

    it "marks a deleted Node as not saved" do
      @test_node.destroy!.should be_true
      @test_node.should_not be_saved
    end
  end
  
  describe "class" do
    describe "#exists?" do
      it "returns true when a node with the desired key exists" do
        TestNode.exists?('rolly').should be_true
      end

      it "returns false when a node with the desired key does not exist" do
        TestNode.exists?('figs!').should be_false
      end
    end

    describe "#get" do
      it "returns a Node by it's key" do
        TestNode.get('rolly').should_not be_nil
      end

      it "returns nil when getting a Node that doesn't exist" do
        TestNode.get('figs!').should be_nil
      end
    end

    describe "#get!" do
      it "returns a Node by it's key" do
        TestNode.get('rolly').should_not be_nil
      end

      it "raises an RedisGraph::NodeNotFoundError exception when getting a Node that doesn't exist" do
        lambda {
          TestNode.get!('figs!')
        }.should raise_error(RedisGraph::NodeNotFoundError)
      end
    end

    describe "#key" do
      
      it "returns the value of the Property that is the key" do
        @test_node.key.should == @test_node.name
      end

      it "should automagically create an key property when one is not defined" do
        class TestNode2
          include RedisGraph::Node

          property :name,         String
          property :age,          Integer
          property :mood,         String
        end
        
        test = TestNode2.new :name => 'bob'
        test.key.should_not be_blank
      end
    end
  end

end
