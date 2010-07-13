require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Set do
  class RedisGraph::Set
    attr_reader :raw
  end
  
  before(:all) do
    @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
  end

  describe "#get" do
    it "retrieves a set by name" do
      @test_node.send_command( 'set', :sadd, 'bob' )
      set = RedisGraph::Set.get(@test_node, 'set')
      set.to_a.should == ['bob']
    end

    it "retrieves a set with the default value (an empty set) if no set exists for a specific name" do
      RedisGraph::Set.get(@test_node, 'bob').raw.should == ::Set.new
    end
  end
  
  describe "#set" do
    it "adds a value to the set in Redis" do
      set = RedisGraph::Set.get(@test_node, 'set')
      set.should == ::Set.new
      set.replace(['foo', 'bar'])

      RedisGraph::Set.get(@test_node, 'set').should == ::Set.new(['foo', 'bar'])
    end
    
    it "fails to adds a value to the set in Redis when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')
      set = RedisGraph::Set.get(@test_node2, 'set')
      
      lambda {
        set.replace(['foo', 'bar'])
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end

  describe "#reload" do
    it "can be reloaded from the Data Store" do
      set = RedisGraph::Set.get(@test_node, 'set')
      set.replace(['foo', 'bar'])

      @test_node.send_command( 'set', :sadd, 'baz' )
      set.reload
      set.should == ::Set.new(['foo', 'bar', 'baz'])
    end
  end

  describe "#size" do
    it "retrieves the size of an existing set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )      

      set = RedisGraph::Set.get(@test_node, 'set')
      set.size.should == 2
    end

    it "retrieves the size of a non-existant set" do
      set = RedisGraph::Set.get(@test_node, 'set')
      set.size.should == 0
    end

    it "aliases #length to #size" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )      

      set = RedisGraph::Set.get(@test_node, 'set')
      set.length.should == 2
    end

    it "retrieves the set size from the data store rather than caching it" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )      

      set = RedisGraph::Set.get(@test_node, 'set')
      set.size.should == 2

      @test_node.send_command( 'set', :sadd, 'baz' )
      # No reload needed here
      set.size.should == 3
    end
  end # #size

  describe "#empty?" do
    it "returns false for a non empty set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )      

      set = RedisGraph::Set.get(@test_node, 'set')
      set.should_not be_empty
    end

    it "returns true for a non-existant set" do
      set = RedisGraph::Set.get(@test_node, 'set')
      set.should be_empty
    end
  end # #empty?

  describe "#include?" do
    it "returns true when the search element is in the set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.should include('foo')
      set.should include('bar')
    end

    it "returns false when the search element is not in the set" do
      @test_node.send_command( 'set', :sadd, 'bar' )
      set = RedisGraph::Set.get(@test_node, 'set')
      set.should_not include('foo')
    end
  end # #include?

  describe "#add" do
    it "adds an element to an existing set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.add 'baz'
      set.reload
      set.should include('baz')
    end

    it "adds an element to an existing set only once" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.add 'baz'
      set.reload
      set.size.should == 3
      set.should == ::Set.new(['foo', 'bar', 'baz'])
    end

    it "adds an element to an non-existant set" do
      @test_node.send_command( 'set', :exists ).should be_false
      set = RedisGraph::Set.get(@test_node, 'set')
      set.should be_empty
      set.add 'baz'
      set.reload
      set.should include('baz')
      @test_node.send_command( 'set', :exists ).should be_true
    end

    it "fails to adds an element to an existing set when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'set', :sadd, 'foo' )
      @test_node2.send_command( 'set', :sadd, 'bar' )
      set = RedisGraph::Set.get(@test_node2, 'set')
      
      lambda {
        set.add 'baz'
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end # #add

  describe "#delete" do
    it "removes an element from an existing set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.delete 'bar'
      set.reload
      set.should_not include('bar')
      set.should include('foo')
    end

    it "removes only one element at a time" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.delete 'bar'
      set.reload
      set.size.should == 1
      set.should == ::Set.new(['foo'])
    end

    it "does nothing when attempting to remove a non-existant set element" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.delete 'baz'
      set.reload
      set.size.should == 2
      set.should == ::Set.new(['foo', 'bar'])
    end

    it "deletes the set in the data store when deleting the last element" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      set = RedisGraph::Set.get(@test_node, 'set')
      set.delete 'foo'
      set.reload
      set.should be_empty
      @test_node.send_command( 'set', :exists ).should be_false
    end

    it "fails to removes an element from an existing set when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'set', :sadd, 'foo' )
      @test_node2.send_command( 'set', :sadd, 'bar' )
      set = RedisGraph::Set.get(@test_node2, 'set')
      
      lambda {
        set.delete 'bar'
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end # #delete

  describe "#merge" do
    it "adds multiple elements to an existing set" do
      @test_node.send_command( 'set', :sadd, 'foo' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.merge ['bar', 'baz']
      set.reload
      set.should include('foo')
      set.should include('bar')
      set.should include('baz')
    end

    it "adds multiple elements to a nonexistant set" do
      set = RedisGraph::Set.get(@test_node, 'set')
      set.merge ['bar', 'baz']
      set.reload
      set.should include('bar')
      set.should include('baz')
    end

    it "fails to adds multiple elements to an existing set when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'set', :sadd, 'foo' )
      set = RedisGraph::Set.get(@test_node2, 'set')
      
      lambda {
        set.merge ['bar', 'baz']
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end # #merge

  describe "#subtract" do
    it "removes multiple elements from an existing set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )
      @test_node.send_command( 'set', :sadd, 'baz' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.subtract ['bar', 'baz']
      set.reload
      set.should include('foo')
      set.should_not include('bar')
      set.should_not include('baz')
    end

    it "does nothing when removing multiple elements from a nonexistant set" do
      set = RedisGraph::Set.get(@test_node, 'set')
      set.subtract ['bar', 'baz']
      set.reload
      set.should be_empty
      @test_node.send_command( 'set', :exists ).should be_false
    end

    it "fails to removes multiple elements from an existing set when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'set', :sadd, 'foo' )
      @test_node2.send_command( 'set', :sadd, 'bar' )
      @test_node2.send_command( 'set', :sadd, 'baz' )
      set = RedisGraph::Set.get(@test_node2, 'set')
      
      lambda {
        set.subtract ['bar', 'baz']
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end # #merge

  describe "#clear" do
    it "clears all elements from an existing set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )
      @test_node.send_command( 'set', :sadd, 'baz' )

      set = RedisGraph::Set.get(@test_node, 'set')
      set.clear
      set.reload
      set.should be_empty
    end

    it "does nothing when clearing multiple elements from a nonexistant set" do
      set = RedisGraph::Set.get(@test_node, 'set')
      set.clear
      set.reload
      set.should be_empty
      @test_node.send_command( 'set', :exists ).should be_false
    end

    it "fails to clears all elements from an existing set when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'set', :sadd, 'foo' )
      @test_node2.send_command( 'set', :sadd, 'bar' )
      @test_node2.send_command( 'set', :sadd, 'baz' )
      set = RedisGraph::Set.get(@test_node2, 'set')
      
      lambda {
        set.clear
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end # #clear

  describe "#==" do
    describe "A == B" do
      it "returns true when comparing two sets with identical contents" do
        @test_node.send_command( 'set1', :sadd, 'foo' )
        @test_node.send_command( 'set1', :sadd, 'bar' )

        @test_node.send_command( 'set2', :sadd, 'foo' )
        @test_node.send_command( 'set2', :sadd, 'bar' )

        set1 = RedisGraph::Set.get(@test_node, 'set1')
        set2 = RedisGraph::Set.get(@test_node, 'set2')
        set1.should == set2
      end

      it "returns true when comparing a set with Ruby Set, with identical contents" do
        @test_node.send_command( 'set1', :sadd, 'foo' )
        @test_node.send_command( 'set1', :sadd, 'bar' )

        set1 = RedisGraph::Set.get(@test_node, 'set1')
        set2 = ::Set.new(['foo', 'bar'])
        set1.should == set2
      end

      it "returns true when comparing a set with Ruby Array, with identical contents" do
        @test_node.send_command( 'set1', :sadd, 'foo' )
        @test_node.send_command( 'set1', :sadd, 'bar' )

        set1 = RedisGraph::Set.get(@test_node, 'set1')
        set2 = ::Set.new(['foo', 'bar'])
        set1.should == set2
      end
    end # A == B

    describe "A != B" do
      it "returns false when comparing two sets with non-identical contents" do
        @test_node.send_command( 'set1', :sadd, 'foo' )
        @test_node.send_command( 'set1', :sadd, 'bar' )

        @test_node.send_command( 'set2', :sadd, 'foo' )

        set1 = RedisGraph::Set.get(@test_node, 'set1')
        set2 = RedisGraph::Set.get(@test_node, 'set2')
        set1.should_not == set2
      end

      it "returns false when comparing a set with Ruby Set, with non-identical contents" do
        @test_node.send_command( 'set1', :sadd, 'foo' )
        @test_node.send_command( 'set1', :sadd, 'bar' )

        set1 = RedisGraph::Set.get(@test_node, 'set1')
        set2 = ::Set.new(['foo'])
        set1.should_not == set2
      end

      it "returns false when comparing a set with Ruby Array, with non-identical contents" do
        @test_node.send_command( 'set1', :sadd, 'foo' )
        @test_node.send_command( 'set1', :sadd, 'bar' )

        set1 = RedisGraph::Set.get(@test_node, 'set1')
        set2 = ['foo']
        set1.should_not == set2
      end
    end # A != B

  end # #==

  describe "#each" do
    it "iterates over each element in an existing set" do
      @test_node.send_command( 'set', :sadd, 'foo' )
      @test_node.send_command( 'set', :sadd, 'bar' )
      @test_node.send_command( 'set', :sadd, 'baz' )

      set = RedisGraph::Set.get(@test_node, 'set')

      values = []
      set.each do |value|
        values << value
      end

      values.sort.should == ['bar', 'baz', 'foo']
    end
  end # #each
=begin
reload
size
length
empty?
include?
add
merge
delete
subtract
clear
each
==
&
intersection
|
union
-
difference
=end

end