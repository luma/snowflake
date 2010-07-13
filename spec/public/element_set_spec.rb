require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Element::Plugins::Sets do
#  before(:all) do
#  end

  class TestNodeWithSet
    include RedisGraph::Node

    attribute :name,         String, :key => true
    attribute :age,          Integer
    attribute :mood,         String
    attribute :description,  String
    
    set :set
  end

  describe "#class" do
    it "has a list of it's sets" do
      TestNodeWithSet.sets == [:set]
    end
  end
  
  it "reads the set instance" do
    @node = TestNodeWithSet.new(:name => 'bob')
    @node.set.should be_an_instance_of RedisGraph::Set
  end

  it "writes to the set instance" do
    @node = TestNodeWithSet.create(:name => 'bob')
    @node.set.should == ::Set.new
    @node.set = ::Set.new(['foo', 'bar', 'baz'])
    @node.set.should == ::Set.new(['foo', 'bar', 'baz'])

    @node = TestNodeWithSet.new(:name => 'bob')
    @node.set.should == ::Set.new(['foo', 'bar', 'baz'])
  end

  it "refuses to write to the set instance until the element is persisted" do
    @node = TestNodeWithSet.new(:name => 'bob')
    @node.set.should == ::Set.new
    
    lambda {
      @node.set = ::Set.new(['foo', 'bar', 'baz'])
    }.should raise_error(RedisGraph::NotPersisted)
  end




end
