require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::PropertyPrototype do
#  before(:all) do
#  end
  
  describe "#to_property" do
    it "returns a new property for a node" do
      node = TestNode.new
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, String)
      property = pt.to_property(node)
      puts property.inspect
      property.is_a?(RedisGraph::Properties::String).should be_true
    end
  end
  
  describe "#property_class_for_type" do
    it "returns a Property class for @type" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, String)
      pt.property_class_for_type.should == RedisGraph::Properties::String
    end
  end
  
  describe "#value_for_key" do
    after(:each) do
      #RedisGraph.flushdb
      RedisGraph.connection.del( 'foo' )
    end

    it "returns a String value for a key" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, String)
      RedisGraph.connection['foo'] = 'bar'
      pt.value_for_key('foo').should == 'bar'
    end
    
    it "returns a Boolean value for a key" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, ::RedisGraph::Properties::Boolean)
      RedisGraph.connection['foo'] = '1'
      pt.value_for_key('foo').should == '1'
    end

    it "returns a Integer value for a key" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, Integer)
      RedisGraph.connection['foo'] = 100
      pt.value_for_key('foo').should == '100'
    end

    it "returns a Counter value for a key" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, ::RedisGraph::Properties::Counter)
      RedisGraph.connection['foo'] = 2
      pt.value_for_key('foo').should == '2'
    end

    it "returns a Set value for a key" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, ::RedisGraph::Properties::Set)
      RedisGraph.connection.sadd( 'foo', 'foo')
      RedisGraph.connection.sadd( 'foo', 'bar')
      RedisGraph.connection.smembers( 'foo' ).should == [ 'foo', 'bar' ]
    end

    it "returns a List value for a key" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, ::RedisGraph::Properties::List)
      RedisGraph.connection.rpush( 'foo', 'foo')
      RedisGraph.connection.rpush( 'foo', 'bar')
      RedisGraph.connection.lrange( 'foo', 0, -1 ).should == ['foo', 'bar']
    end

    it "returns a Hash value for a key" do
      pt = RedisGraph::PropertyPrototype.new(TestNode, :name, ::RedisGraph::Properties::Hash)
      RedisGraph.connection.hmset( 'foo', :foo, 'bar' )
      RedisGraph.connection.hgetall( 'foo' ).should == {'foo' => 'bar'}
    end
  end
end

=begin
# Retrieves a value from Redis by it's Key, the retrieval method used depends on the
# Properties type.
#
# @todo This is a bit of a kludge right now. I'd rather this method was necessary at all.
#
# @param [#to_s] key
#     The Property key to retrieve
#
# @return [Various]
#     The Property value
#
# @api semi public
def value_for_key(key)
  case @type.to_s
  when "RedisGraph::Properties::Set"
    RedisGraph.connection.smembers( key )
  when "RedisGraph::Properties::List"
    RedisGraph.connection.lrange( key, 0, -1 )
  when "RedisGraph::Properties::Hash"
    RedisGraph.connection.hgetall( key )
  else
    # When in doubt, assume a string
    RedisGraph.connection.get( key )
  end
end
=end