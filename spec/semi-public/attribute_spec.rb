require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Attribute do
  describe "class" do
    describe "#get" do
      it "returns a valid Property Class by type" do
        RedisGraph::Attribute.get("String").should_not be_nil
      end

      it "returns nil for an invalid type" do
        RedisGraph::Attribute.get("Foo").should be_nil
      end
    end
  end
end
