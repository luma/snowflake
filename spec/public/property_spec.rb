require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

class TestPrimitive
  def to_s
    'foo'
  end
  
  def inspect
    to_s.inspect
  end
end

module RedisGraph
  module Properties
    class TestNonPrimitive < Property
      primitive false

      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options)
      end

      def to_s
        @raw
      end

      def raw=(raw)
        @raw = raw.to_s
      end

      def store!
        @node.send_command( @name, :set, to_s )
      end
    end

    class TestPrimitive < Property
      alias_for ::TestPrimitive
      primitive true

      def initialize(node, name, raw_value, options = {})
        super(node, name, raw_value, options)
      end

      def to_s
        @raw
      end

      def raw=(raw)
        @raw = raw.to_s
      end

      def store!
        @node.send_command( @name, :set, to_s )
      end
    end
  end
end

describe RedisGraph::Property do
  describe "#primitive?" do
    before(:all) do
      @test_node = TestNode.new
    end

    it "return true when a Property is a Primitive" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, String)
      pt.to_property(@test_node).should be_primitive
    end

    it "indicate whether this Property is a primitive" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :tags, ::RedisGraph::Properties::Set)
      pt.to_property(@test_node).should_not be_primitive
    end
  end
  
  describe "#inspect" do
    it "inspects a String Property as a Primitive String" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, String)
      prop = pt.to_property(@test_node)
      prop.raw = "Bob"
      prop.inspect.should == "Bob".inspect
    end

    it "inspects a Boolean Property as a Primitive TrueClass" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :enabled, ::RedisGraph::Properties::Boolean)
      prop = pt.to_property(@test_node)
      prop.raw = true
      prop.inspect.should == true.inspect
    end

    it "inspects a Integer Property as a Primitive Integer" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :age, Integer)
      prop = pt.to_property(@test_node)
      prop.raw = 12
      prop.inspect.should == 12.inspect
    end

    it "inspects a Counter Property as a Primitive Integer" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :visits, ::RedisGraph::Properties::Counter)
      prop = pt.to_property(@test_node)
      prop.raw = 12
      prop.inspect.should == 12.inspect
    end

    it "inspects a Set Property as a Primitive Set" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :tags, ::RedisGraph::Properties::Set)
      prop = pt.to_property(@test_node)
      prop.raw = [1, 2, 3, 4, 5]
      prop.inspect.should == Set.new([1, 2, 3, 4, 5]).inspect
    end

    it "inspects a List Property as a Primitive Array" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :awards, ::RedisGraph::Properties::List)
      prop = pt.to_property(@test_node)
      prop.raw = [1, 2, 3, 4, 5]
      prop.inspect.should == [1, 2, 3, 4, 5].inspect
    end
  end
  
=begin
# Writes the value of this Property to the Redis store.
#
# @api public
def store!
  raise NotImplemented, "Valid Properties have to subclass the Property Class and implement the 'store' method."
end
=end
  
  describe "child class" do
    describe "#primitive?" do
      it "return true when a Property is a Primitive" do
        RedisGraph::Properties::TestPrimitive.should be_primitive
      end

      it "indicate whether this Property is a primitive" do
        RedisGraph::Properties::TestNonPrimitive.should_not be_primitive
      end
    end
    
    describe "#aliases" do
      it "returns all the Property aliases" do
        RedisGraph::Properties::TestPrimitive.aliases.should == Set.new([::TestPrimitive])
        RedisGraph::Properties::TestNonPrimitive.aliases.should == Set.new
      end
    end
  end
  
  describe "class" do
    describe "#aliases" do
      it "returns all the Property aliases for all Properties" do
        RedisGraph::Property.aliases.should == {
          "TestPrimitive"=>"RedisGraph::Properties::TestPrimitive", 
          "Integer"=>"RedisGraph::Properties::Integer", 
          "Hash"=>"RedisGraph::Properties::Hash", 
          "String"=>"RedisGraph::Properties::String", 
          "TrueClass"=>"RedisGraph::Properties::Boolean"
        }
      end
    end
  end
end
