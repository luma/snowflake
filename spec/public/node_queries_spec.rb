require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  before(:each) do
    @test_nodes = []

    10.times do |i|
      @test_nodes << TestNode.create(:name => "test #{i}", :mood => "Awesome #{(i%2).to_i}", :age => (i + 20) )
    end
  end

  describe "#all" do
    it "returns all elements" do
      nodes = TestNode.all
      nodes.length.should == 10
      nodes.all.sort.should == @test_nodes.sort
    end

    it "filters the nodes via a match against a single field" do
      even = TestNode.all( :mood => "Awesome 0")
      even.length.should == 5      
      even.all.sort.should == @test_nodes.dup.delete_if {|n| n.mood == 'Awesome 1' }.sort

      odd = TestNode.all( :mood => "Awesome 1")
      odd.length.should == 5
      odd.all.sort.should == @test_nodes.dup.delete_if {|n| n.mood == 'Awesome 0' }.sort
    end

    it "filters the nodes via a match against multiple values ANDed together" do
      TestNode.all( :mood => "Awesome 0" ).and( :age => 28 ).all.should == [@test_nodes[8]]
    end
    
    it "returns an empty collection when filtering for two values on an attribute that only accepts one" do
      # Should be empty as no TestNode can have a mood of Both "Awesome 0" and "Awesome 1"
      TestNode.all( :mood => "Awesome 0" ).and( :mood => "Awesome 1" ).all.should be_empty
    end

    it "returns nodes when filtering with two values against an attribute that accept two values" do
      @test_node2 = TestNodeWithCustomAttributes.create(:name => 'rolly', :mood => 'Awesome')
      @test_node2.stuff = ['foo', 'bar']

      nodes = TestNodeWithCustomAttributes.all( :stuff => ['foo', 'bar'] ).all
      nodes.first.should == @test_node2
    end

    it "filters the nodes via a match against multiple values ANDed together" do
      TestNode.all( :mood => "Awesome 0" ).or( :mood => "Awesome 1" ).all.sort.should == TestNode.all.all.sort
    end

    it "filters the nodes via two values ORed together" do
      3.times do |i|
        @test_nodes << TestNode.create(:name => "test #{10 + i}", :mood => "Awesome 3")
      end

      nodes = TestNode.all( :mood => "Awesome 0" ).or( :mood => "Awesome 3" )
      nodes.length.should == 8
      nodes.all.sort.should == TestNode.all( :mood => "Awesome 0").all.concat( TestNode.all( :mood => "Awesome 3").all ).sort
    end
    
    it "filters the nodes via a complex filter involving ANDing and ORing" do
      pending
    end
  end
end