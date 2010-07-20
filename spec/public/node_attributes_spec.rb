require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  describe "Attributes" do
    it "indicates whether an attribute name represents a attribute on this element" do
      TestNode.has_attribute?( :name ).should be_true
      TestNode.has_attribute?( :age ).should be_true
      TestNode.has_attribute?( :foo ).should be_false
    end
    
    it "retrieves a list of all custom attributes" do
      TestNode.attributes.should == Set.new([:name, :age, :mood, :description, :enabled])
    end

    describe "Assignment" do
      before :each do
        @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
      end

      it "will read a value from an attribute" do
        @test_node.mood.should == 'Awesome'
      end
      
      it "will assign a value to an attribute" do
        @test_node.mood = 'Dire'
        @test_node.mood.should == 'Dire'
      end

      it "will retrieve the attributes as a hash" do
        @test_node.attributes.should == {
          :name => 'rolly',
          :mood => 'Awesome'
        }
      end

      it "will mass-assign a hash of attributes" do
        @test_node.attributes = {
          :mood => 'Peachy',
          :age  => 1000
        }
        
        @test_node.mood.should == 'Peachy'
        @test_node.age.should == 1000
      end

      it "will mass-assign a hash of attributes and save the element" do
        @test_node.update_attributes({
          :mood => 'Peachy',
          :age  => 1000
        })

        @test_node.mood.should == 'Peachy'
        @test_node.age.should == 1000
      end
    end

  end
end
