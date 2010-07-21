# Changed the semantics of writing values to custom attributes to ensure that they

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  describe "Dirty" do
    before(:each) do
      @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
    end

    describe "Changed Attributes" do
      it "indicates if an attribute has been changed" do
        @test_node.name_changed?.should be_false
        @test_node.name = 'bar'
        @test_node.name_changed?.should be_true
      end

      it "returns the old value" do
        @test_node.name = 'bar'
        @test_node.name_was.should == 'rolly'
      end

      it "returns the old and current values" do
        @test_node.name = 'bar'
        @test_node.name_change.should == ['rolly', 'bar']
      end

      it "resets a modified value" do
        @test_node.name = 'bar'
        @test_node.name_changed?.should be_true
        @test_node.reset_name!
        
        @test_node.name.should == 'rolly'
        @test_node.name_was.should == 'bar'
        @test_node.name_change.should == ['bar', 'rolly']
      end
    end
    
  end
end