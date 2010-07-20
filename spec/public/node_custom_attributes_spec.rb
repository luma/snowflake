# Changed the semantics of writing values to custom attributes to ensure that they

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  class TestNodeWithCustomAttributes
    include Snowflake::Node

    attribute :name,         String, :key => true
    attribute :age,          Integer
    attribute :mood,         String
    attribute :description,  String

    validates_presence_of :name

    counter :counter
    set :stuff
  end
  
  describe "Custom Attributes" do
    it "indicates whether an attribute name represents a custom attribute" do
      TestNodeWithCustomAttributes.custom_attribute?( :counter ).should be_true
      TestNodeWithCustomAttributes.custom_attribute?( :stuff ).should be_true
      TestNodeWithCustomAttributes.custom_attribute?( :name ).should be_false
      TestNodeWithCustomAttributes.custom_attribute?( :foo ).should be_false
    end
    
    it "retrieves a list of all custom attributes" do
      TestNodeWithCustomAttributes.custom_attributes.should == Set.new([:counter, :stuff])
    end

    it "will overwrite and persist custom attribute values" do
      @test_node = TestNodeWithCustomAttributes.create(:name => 'rolly', :mood => 'Awesome')
      @test_node.should be_valid

      @test_node.stuff = ['foo', 'bar']
      @test_node.should be_valid

      @test_node = TestNodeWithCustomAttributes.get( @test_node.key )
      @test_node.stuff.to_set.should == Set.new(['foo', 'bar'])
    end

    it "will raise an exception if errors occur when overwriting custom attribute values" do
      @test_node = TestNodeWithCustomAttributes.create(:name => 'rolly', :mood => 'Awesome')
      @test_node.should be_valid

      lambda {
        @test_node.stuff = "Yo"
      }.should raise_error(Snowflake::CouldNotPersistCustomAttributeError)

      @test_node = TestNodeWithCustomAttributes.get( @test_node.key )
      @test_node.stuff.to_set.should == Set.new
    end

    it "will not allow custom attributes to be overwritten when there are existing errors" do
      @test_node = TestNodeWithCustomAttributes.create(:name => 'rolly', :mood => 'Awesome')
      @test_node.should be_valid

      @test_node.name = nil

      lambda {
        @test_node.stuff = ['foo', 'bar']
      }.should raise_error(Snowflake::CustomAttributeError)
    end
  end
end
