require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Element do
  describe "Counters" do
  #  before(:all) do
  #  end

    class TestNodeWithCounter
      include Snowflake::Node

      attribute :name,         String, :key => true
      attribute :age,          Integer
      attribute :mood,         String
      attribute :description,  String
    
      counter :counter
    end
  
    it "reads the counter instance" do
      @node = TestNodeWithCounter.new(:name => 'bob')
      @node.counter.should be_an_instance_of Snowflake::CustomAttributes::Counter
    end

    it "writes to the counter instance" do
      @node = TestNodeWithCounter.create(:name => 'bob')
      @node.counter.should == 0
      @node.counter = 10
      @node.counter.should == 10

      @node = TestNodeWithCounter.new(:name => 'bob')
      @node.counter.should == 10
    end

    it "refuses to write to the counter instance until the element is persisted" do
      @node = TestNodeWithCounter.new(:name => 'bob')
      @node.counter.should == 0

      lambda {
        @node.counter = 10
      }.should raise_error(Snowflake::NotPersisted)
    end

  end
end