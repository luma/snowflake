require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::PropertyPrototype do
#  before(:all) do
#  end
  
  describe "#id?" do
    it "should not be an ID field by default" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, String).should_not be_id
    end

    it "returns true for ID if :id => true is part of the options" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, String, :id => true).should be_id
    end
  end
  
  describe "#primitve?" do
    it "returns true when it represents a Primitive Property" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, String, :id => true).should be_primitive
    end
    
    it "returns false when it doesn't represents a Primitive Property" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, ::RedisGraph::Properties::Counter, :id => true).should_not be_primitive
    end
  end
end
