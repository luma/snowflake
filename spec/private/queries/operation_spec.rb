require File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), '..', 'spec_helper'))

describe Snowflake::Queries::Operation do
  describe "#to_key" do
    before :each do
      Snowflake.connection.sadd('TestNode::indices::foo', '1')
      Snowflake.connection.sadd('TestNode::indices::foo', '2')
      @operand1 = Snowflake::Queries::Operand.new(TestNode, 'foo')

      Snowflake.connection.sadd('TestNode::indices::bar', '2')
      Snowflake.connection.sadd('TestNode::indices::bar', '3')
      @operand2 = Snowflake::Queries::Operand.new(TestNode, 'bar')
    end

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
      describe "AND" do
        before :each do
          Snowflake.connection.sadd('TestNode::indices::foo', '1')
          Snowflake.connection.sadd('TestNode::indices::foo', '2')
          @operand1 = Snowflake::Queries::Operand.new(TestNode, 'foo')

          Snowflake.connection.sadd('TestNode::indices::bar', '2')
          Snowflake.connection.sadd('TestNode::indices::bar', '3')
          @operand2 = Snowflake::Queries::Operand.new(TestNode, 'bar')

          @op = Snowflake::Queries::Operations::AndOperation.new(@operand1, @operand2)
          @commands = @op.eval(nil, true)
        end

        it "returns a correctly formatted command" do
          @commands.first.should == [:sinter, 'TestNode::indices::foo', 'TestNode::indices::bar']
        end

        it "returns a valid command" do
          Snowflake.connection.send( *@commands.first ).should == ['2']
          #Snowflake.connection.send( *[:smembers, @commands.first[1]] ).sort.should == ['2']
        end
      end

      describe "OR" do
        before :each do
          Snowflake.connection.sadd('TestNode::indices::foo', '1')
          Snowflake.connection.sadd('TestNode::indices::foo', '2')
          @operand1 = Snowflake::Queries::Operand.new(TestNode, 'foo')

          Snowflake.connection.sadd('TestNode::indices::bar', '2')
          Snowflake.connection.sadd('TestNode::indices::bar', '3')
          @operand2 = Snowflake::Queries::Operand.new(TestNode, 'bar')

          @op = Snowflake::Queries::Operations::OrOperation.new(@operand1, @operand2)
          @commands = @op.eval(nil, true)
        end

        it "returns a correctly formatted command" do
          @commands.first.should == [:sunion, 'TestNode::indices::foo', 'TestNode::indices::bar']
        end

        it "returns a valid command" do
          Snowflake.connection.send( *@commands.first ).sort.should == ['1', '2', '3']
        end
      end
    end

    describe "Nested Operations" do
      before :each do
        Snowflake.connection.sadd('TestNode::indices::foo', '1')
        Snowflake.connection.sadd('TestNode::indices::foo', '2')
        @operand1 = Snowflake::Queries::Operand.new(TestNode, 'foo')

        Snowflake.connection.sadd('TestNode::indices::bar', '2')
        Snowflake.connection.sadd('TestNode::indices::bar', '3')
        @operand2 = Snowflake::Queries::Operand.new(TestNode, 'bar')

        Snowflake.connection.sadd('TestNode::indices::baz', '3')
        Snowflake.connection.sadd('TestNode::indices::baz', '4')
        @operand3 = Snowflake::Queries::Operand.new(TestNode, 'baz')

        @op1 = Snowflake::Queries::Operations::AndOperation.new(@operand1, @operand2)
        @op2 = Snowflake::Queries::Operations::OrOperation.new(@op1, @operand3)
        @commands = @op2.eval(nil, true)
      end

      it "evals the correct number of steps" do
        @commands.length.should == 2
      end

      it "returns a correctly formatted command" do
        @commands.first.should == [:sinterstore, @op1.to_key, 'TestNode::indices::foo', 'TestNode::indices::bar']
        @commands.last.should  == [:sunion,  @op1.to_key, 'TestNode::indices::baz']
      end

      it "returns a valid command" do
        Snowflake.connection.send( *@commands.first ).should_not be_blank
        Snowflake.connection.smembers( @commands.first[1] ).sort == ['2']
        Snowflake.connection.send( *@commands.last ).sort.should == ['2', '3', '4']
      end
    end
  end
end