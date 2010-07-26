require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  before(:each) do
    @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
  end

  describe "#persisted?" do
    it "indicates when a Node has been saved" do
      @test_node.should be_persisted
    end
    
    it "indicates when a Node has not been saved" do
      TestNode.new.should_not be_persisted
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
      @test_node.errors[:name].should_not be_blank
    end
    
    it "should not save a new Node with a key that's identical to an existing one" do
      node = TestNode.new(:name => @test_node.name)
      node.save.should be_false
      node.errors[:name].should_not be_blank
    end
  end
  
  describe "#destroy" do
    it "deletes a saved Node" do
      @test_node.destroy.should be_true
      TestNode.get('rolly').should be_nil
    end

    it "marks a deleted Node as not saved" do
      @test_node.destroy.should be_true
      @test_node.should_not be_persisted
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

    it "deletes an existing Node" do
      TestNode.destroy!('rolly').should be_true
      TestNode.get('rolly').should be_nil
    end

    describe "#get!" do
      it "returns a Node by it's key" do
        TestNode.get('rolly').should_not be_nil
      end

      it "raises an Snowflake::NotFoundError exception when getting a Node that doesn't exist" do
        lambda {
          TestNode.get!('figs!')
        }.should raise_error(Snowflake::NotFoundError)
      end
    end

    describe "#key" do
      
      it "returns the value of the Property that is the key" do
        @test_node.key.should == @test_node.name
      end

      it "should automagically create an key property when one is not defined" do
        class TestNode2
          include Snowflake::Node

          attribute :name,         String
          attribute :age,          Integer
          attribute :mood,         String
        end
        
        test = TestNode2.new :name => 'bob'
        test.key.should_not be_blank
      end
    end
    
    describe "#all" do
      it "returns all elements" do
        all = TestNode.all
        all.length.should == 1
        all.should == [@test_node]
      end

      it "returns all elements filtered by indices" do
        pending
      end
    end
  end

  describe "Dynamic Attributes" do
    it "can disable dynamic attributes for the entire model" do
      pending
    end

    it "can dynamically create attributes using #attributes=" do
      pending
    end

    it "can register dynamic attributes using #add_dynamic_attribute" do
      pending
    end

    describe "#dynamic_attribute?" do
      it "can indicate if an attribute is dynamic" do
        pending
      end
      
      it "can indicate if an attribute is not dynamic" do
        pending
      end
    end
  end

  describe "Inheritance" do
    it "should have specs" do
      pending
    end
  end

  describe "Serialisation" do
    it "should serialise to a hash" do
      @test_node.attributes.should == {'name' => 'rolly', 'mood' => 'Awesome'}
    end

    it "should serialise to JSON" do
      @test_node.to_json.should == {'test_node' => {'name' => 'rolly', 'mood' => 'Awesome'}}.to_json
    end

    it "should serialise to XML" do
      @test_node.to_xml.should == <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<test-node>
  <name>rolly</name>
  <mood>Awesome</mood>
</test-node>
EOS
    end
  end
end
