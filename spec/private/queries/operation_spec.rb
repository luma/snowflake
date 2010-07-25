require File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), '..', 'spec_helper'))

describe Snowflake::Queries::Operation do

  describe Snowflake::Queries::Operation do
    describe "#to_key" do
      it "returns a dynamically created key, if none is provided" do
        # @todo this is a pretty terrible test of randomness, need to research a better way to do this
        keys = []
        20.times do |i|
          op = Snowflake::Queries::Operations::AndOperation.new(@operand1, @operand2)
          keys.should_not include(op.to_key)
          keys << op.to_key
        end
      end
    end

    describe "#eval" do
      describe "Simple Operands" do
        before :each do
          Snowflake.connection.sadd('foo', '1')
          Snowflake.connection.sadd('foo', '2')
          @operand1 = Snowflake::Queries::Operand.new('foo')

          Snowflake.connection.sadd('bar', '2')
          Snowflake.connection.sadd('bar', '3')
          @operand2 = Snowflake::Queries::Operand.new('bar')

          @op = Snowflake::Queries::Operations::AndOperation.new(@operand1, @operand2)
          @commands = @op.eval
        end

        it "returns a correctly formatted command" do
          @commands.first.should == [:sunionstore, @op.to_key, 'foo', 'bar']
        end

        it "returns a valid command" do
          Snowflake.connection.send( *@commands.first ).should_not be_blank
          Snowflake.connection.send( *[:smembers, @commands.first[1]] ).sort.should == ['1', '2', '3']
        end
      end

      describe "Nested Operations" do
        before :each do
          Snowflake.connection.sadd('foo', '1')
          Snowflake.connection.sadd('foo', '2')
          @operand1 = Snowflake::Queries::Operand.new('foo')

          Snowflake.connection.sadd('bar', '2')
          Snowflake.connection.sadd('bar', '3')
          @operand2 = Snowflake::Queries::Operand.new('bar')

          Snowflake.connection.sadd('baz', '3')
          Snowflake.connection.sadd('baz', '4')
          @operand3 = Snowflake::Queries::Operand.new('baz')

          @op1 = Snowflake::Queries::Operations::AndOperation.new(@operand1, @operand2)
          @op2 = Snowflake::Queries::Operations::OrOperation.new(@op1, @operand3)
          @commands = @op2.eval
        end

        it "evals the correct number of steps" do
          @commands.length.should == 2
        end

        it "returns a correctly formatted command" do
          @commands.first.should == [:sunionstore, @op1.to_key, 'foo',        'bar']
          @commands.last.should  == [:sinterstore, @op2.to_key,  @op1.to_key, 'baz']
        end

        it "returns a valid command" do
          puts @commands.inspect
          Snowflake.connection.send( *@commands.first ).should_not be_blank
          Snowflake.connection.smembers( @commands.first[1] ).sort == ['1', '2', '3']
          Snowflake.connection.send( *@commands.first ).should_not be_blank
          Snowflake.connection.smembers( @commands.first[1] ) == ['3']
        end
      end
    end
  end
end