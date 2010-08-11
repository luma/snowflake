require File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), '..', 'spec_helper'))

describe Snowflake::Queries::Operation do
  describe "#eval" do
    describe "RANDOM" do
      before :each do
        Snowflake.connection.sadd('TestNode::indices::foo', '1')
        Snowflake.connection.sadd('TestNode::indices::foo', '2')
        @operand1 = Snowflake::Queries::Operand.new(TestNode, 'foo')

        Snowflake.connection.sadd('TestNode::indices::bar', '2')
        Snowflake.connection.sadd('TestNode::indices::bar', '3')
        @operand2 = Snowflake::Queries::Operand.new(TestNode, 'bar')
      end

      describe "Without Filtering" do
        before :each do
          @op = Snowflake::Queries::Operations::RandomOperation.new(@operand1)
          @commands = @op.eval(nil, true)
        end

        it "returns a correctly formatted command" do
          @commands.first.should == [:srandmember, @operand1.to_key]
        end

        it "returns a valid command" do
          Snowflake.connection.send( *@commands.first ).should_not be_blank
        end
      end
      
      describe "With Filtering" do
        before :each do
          @op1 = Snowflake::Queries::Operations::AndOperation.new( @operand1, @operand2 )
          @op2 = Snowflake::Queries::Operations::RandomOperation.new( @op1 )
          @commands = @op2.eval(nil, true)
        end

        it "returns a correctly formatted command" do
          @commands.last.should == [:srandmember, @op1.to_key]
        end

        it "returns a valid command" do
          Snowflake.connection.send( *@commands.last ).should_not be_blank
        end
      end
    end
  end 
end