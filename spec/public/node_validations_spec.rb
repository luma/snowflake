require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  describe "validation" do
    before(:each) do
      @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
    end

    # @todo add proper tests for this
    it "should not save when validation fails" do
      @test_node.mood = nil
      @test_node.save.should be_false
      @test_node.errors[:mood].should_not be_blank
    end
  
    it "should not save a new Node with a key that's identical to an existing one" do
      node = TestNode.new(:name => @test_node.name)
      node.save.should be_false
      node.errors[:mood].should_not be_blank
    end

  end # Validation
end