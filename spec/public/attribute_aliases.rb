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
  module Attributes
    class TestNonPrimitive < Attribute
      primitive false

      def initialize(node, name, options = {})
        super(node, name, options)
      end

      # Convert +value+ to a String
      def dump(value)
        value.to_s
      end

      # Typecasts +value+ to the correct type for this Attribute.
      #
      # @param [Any] value
      #     The value to convert.
      #
      # @return [Any]
      #     A typecast version of +value+.
      # 
      # @api semi-public
      def typecast(value)
        value.to_s
      rescue NoMethodError => e
        raise ArgumentError, "Tried to cast #{value.inspect} to a Guid Attribute. Only values that can be cast to a string (via #to_s) can be assigned to a Guid Attribute."
      end

    end

    class TestPrimitive < Attribute
      alias_for ::TestPrimitive
      primitive true

      def initialize(node, name, options = {})
        super(node, name, options)
      end

      # Convert +value+ to a String
      def dump(value)
        value.to_s
      end

      # Typecasts +value+ to the correct type for this Attribute.
      #
      # @param [Any] value
      #     The value to convert.
      #
      # @return [Any]
      #     A typecast version of +value+.
      # 
      # @api semi-public
      def typecast(value)
        value.to_s
      rescue NoMethodError => e
        raise ArgumentError, "Tried to cast #{value.inspect} to a Guid Attribute. Only values that can be cast to a string (via #to_s) can be assigned to a Guid Attribute."
      end

    end
  end
end

describe RedisGraph::Attribute do
  describe "Aliases" do
    describe "#aliases" do
      it "returns all the Attribute aliases" do
        RedisGraph::Attributes::TestPrimitive.aliases.should == Set.new([::TestPrimitive])
        RedisGraph::Attributes::TestNonPrimitive.aliases.should == Set.new
      end
      
      describe "#aliases" do
        it "returns all the Property aliases for all Properties" do
          RedisGraph::Attribute.aliases.should include("TestPrimitive")
          RedisGraph::Attribute.aliases['TestPrimitive'].should == 'TestPrimitive'
        end
      end
    end
  end # aliases
end