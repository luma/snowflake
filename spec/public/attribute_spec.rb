require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Attribute do
#  before(:all) do
#  end
  
  describe "#key?" do
    it "should not be an key field by default" do
      Snowflake::Attributes::String.new(TestNode, :foo).should_not be_key
    end

    it "returns true for key if :key => true is part of the options" do
      Snowflake::Attributes::String.new(TestNode, :foo, :key => true).should be_key
    end
  end
  
  describe "#primitve?" do
    it "returns true when it represents a Primitive Property" do
      Snowflake::Attributes::String.new(TestNode, :foo, :key => true).should be_primitive
    end
    
    it "returns false when it doesn't represents a Primitive Property" do
      Snowflake::Attributes::Guid.new(TestNode, :foo, :key => true).should_not be_primitive
    end
  end

  describe "#default" do
    it "return the default when there is no other value" do
      Snowflake::Attributes::String.new(TestNode, :foo, :default => 'Yo!').default.should == 'Yo!'
    end

    it "return the default from a lambda/proc when there is no other value" do
      Snowflake::Attributes::String.new(TestNode, :foo, :default => lambda { |element, attribute| "Yo!" }).default.should == 'Yo!'
    end
  end

end
