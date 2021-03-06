require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Attributes do
  describe "class" do
    describe "#get" do
      it "returns a valid Property Class by type" do
        lambda {
          Snowflake::Attributes.get("String").should_not be_nil
        }.should_not raise_error
      end

      it "returns nil for an invalid type" do
        lambda {
          Snowflake::Attributes.get("Foo").should be_nil
        }.should raise_error(ArgumentError)
      end
    end
  end
end
