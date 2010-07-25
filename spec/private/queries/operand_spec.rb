require File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), '..', 'spec_helper'))

describe Snowflake::Queries::Operand do
  before :each do
    Snowflake.connection.sadd('foo', 'baz')
    Snowflake.connection.sadd('foo', 'bar')
    @operand = Snowflake::Queries::Operand.new('foo')
  end

  describe "#to_key" do
    it "returns the correct key" do
      @operand.to_key.should == 'foo'
    end

    it "returns a dynamically created key, if none is provided" do
      # @todo this is a pretty terrible test of randomness, need to research a better way to do this
      keys = []
      20.times do |i|
        op = Snowflake::Queries::Operand.new
        keys.should_not include(op.to_key)
        keys << op.to_key
      end
    end
  end

  describe "#eval" do
    before :each do
      @commands = @operand.eval
    end

    it "returns a correctly formatted command" do
      @commands.first.should == [:smembers, 'foo']
    end

    it "returns a valid command" do
      Snowflake.connection.send( *@commands.first ).should == ['bar', 'baz']
    end
  end
end