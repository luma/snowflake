require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::PropertyPrototype do
#  before(:all) do
#  end
  
  describe "#key?" do
    it "should not be an key field by default" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, String).should_not be_key
    end

    it "returns true for key if :key => true is part of the options" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, String, :key => true).should be_key
    end
  end
  
  describe "#primitve?" do
    it "returns true when it represents a Primitive Property" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, String, :key => true).should be_primitive
    end
    
    it "returns false when it doesn't represents a Primitive Property" do
      RedisGraph::PropertyPrototype.new(TestNode, :foo, ::RedisGraph::Properties::Counter, :key => true).should_not be_primitive
    end
  end
end
