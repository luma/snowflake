require File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), '..', 'spec_helper'))

describe Snowflake::Queries::Operand do
  before :each do
    Snowflake.connection.sadd('TestNode::indices::foo', 'baz')
    Snowflake.connection.sadd('TestNode::indices::foo', 'bar')
    @operand = Snowflake::Queries::Operand.new(TestNode, 'foo')
  end

  describe "#to_key" do
    it "returns the correct key" do
      @operand.to_key.should == 'TestNode::indices::foo'
    end
  end

  describe "#eval" do
    before :each do
      @commands = @operand.eval
    end

    it "returns a correctly formatted command" do
      @commands.first.should == [:smembers, 'TestNode::indices::foo']
    end

    it "returns a valid command" do
      Snowflake.connection.send( *@commands.first ).should == ['bar', 'baz']
    end
  end
end