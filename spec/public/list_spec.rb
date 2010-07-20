require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::CustomAttributes::List do
  class Snowflake::CustomAttributes::List
    attr_reader :raw
  end
  
  before(:all) do
    @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
  end

  describe "#get" do
    it "retrieves a list by name" do
      resp = @test_node.send_command( 'list', :lpush, 'bob' )
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.should == ['bob']
    end

    it "retrieves a list with the default value (an empty list) if no list exists for a specific name" do
      Snowflake::CustomAttributes::List.get(@test_node, 'bob').raw.should == []
    end
  end
  
  describe "#set" do
    it "adds a value to the list in Redis" do
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.should == []
      list.replace(['foo', 'bar'])

      Snowflake::CustomAttributes::List.get(@test_node, 'list').should == ['foo', 'bar']
    end
    
    it "fails to adds a value to the list in Redis when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')
      list = Snowflake::CustomAttributes::List.get(@test_node2, 'list')
      
      lambda {
        list.replace(['foo', 'bar'])
      }.should raise_error(Snowflake::NotPersisted)
    end
  end

  describe "#join" do
    before :each do
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.replace(['foo', 'bar'])
    end

    it "returns the set contents, as a string, glued together with a custom separator" do
      Snowflake::CustomAttributes::List.get(@test_node, 'list').join(', ').should == 'foo, bar'
    end

    it "returns the set contents, as a string, glued together with the default separator" do
      Snowflake::CustomAttributes::List.get(@test_node, 'list').join.should == 'foo bar'
    end
  end # #join

  describe "#reload" do
    it "can be reloaded from the Data Store" do
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.replace(['foo', 'bar'])

      @test_node.send_command( 'list', :rpush, 'baz' )
      list.reload
      list.should == ['foo', 'bar', 'baz']
    end
  end

  describe "#length" do
    it "retrieves the length of an existing list" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.length.should == 2
    end

    it "retrieves the length of a non-existant list" do
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.length.should == 0
    end

    it "retrieves the list length from the data store rather than caching it" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.length.should == 2

      @test_node.send_command( 'list', :rpush, 'baz' )
      # No reload needed here
      list.length.should == 3
    end
  end # #size

  describe "#empty?" do
    it "returns false for a non empty list" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.should_not be_empty
    end

    it "returns true for a non-existant list" do
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.should be_empty
    end
  end # #empty?

  describe "#include?" do
    it "returns true when the search element is in the list" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.should include('foo')
      list.should include('bar')
    end

    it "returns false when the search element is not in the list" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.should_not include('foo')
    end
  end # #include?

  describe "#push" do
    it "adds an element to an existing list" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.push 'baz'
      list.reload
      list.should include('baz')
    end

    it "adds an element to an existing list (using #<<)" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list << 'baz'
      list.reload
      list.should include('baz')
    end

    it "adds an element to an existing list only once" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.push 'baz'
      list.reload
      list.length.should == 3
      list.should == ['foo', 'bar', 'baz']
    end

    it "adds an element to an non-existant list" do
      @test_node.send_command( 'list', :exists ).should be_false
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.should be_empty
      list.push 'baz'
      list.reload
      list.should include('baz')
      @test_node.send_command( 'list', :exists ).should be_true
    end

    it "fails to adds an element to an existing list when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'list', :lpush, 'bar' )
      @test_node2.send_command( 'list', :lpush, 'foo' )
      list = Snowflake::CustomAttributes::List.get(@test_node2, 'list')
      
      lambda {
        list.push 'baz'
      }.should raise_error(Snowflake::NotPersisted)
    end
  end # #add

  describe "#delete" do
    it "removes an element from an existing list" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.delete 'bar'
      list.reload
      list.should_not include('bar')
      list.should include('foo')
    end

    it "removes only one element at a time" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.delete 'bar'
      list.reload
      list.length.should == 1
      list.should == ['foo']
    end

    it "does nothing when attempting to remove a non-existant list element" do
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.delete 'baz'
      list.reload
      list.length.should == 2
      list.should == ['foo', 'bar']
    end

    it "deletes the list in the data store when deleting the last element" do
      @test_node.send_command( 'list', :lpush, 'foo' )
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.delete 'foo'
      list.reload
      list.should be_empty
      @test_node.send_command( 'list', :exists ).should be_false
    end

    it "fails to removes an element from an existing list when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'list', :lpush, 'bar' )
      @test_node2.send_command( 'list', :lpush, 'foo' )
      list = Snowflake::CustomAttributes::List.get(@test_node2, 'list')
      
      lambda {
        list.delete 'bar'
      }.should raise_error(Snowflake::NotPersisted)
    end
  end # #delete
  
  describe "#delete_if" do
    before(:each) do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'list', :lpush, 'baz' )
      @test_node2.send_command( 'list', :lpush, 'bar' )
      @test_node2.send_command( 'list', :lpush, 'foo' )
      @list = Snowflake::CustomAttributes::List.get(@test_node2, 'list')      
    end

    it "deletes every element of the list for which block evaluates to true." do
      l = @list.delete_if do |value|
        value == 'bar'
      end
      
      l.sort.should == ['baz', 'foo']
    end
  end # #delete_if

  describe "#collect" do
    before(:each) do
      @test_node.send_command( 'list', :lpush, 'baz' )
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )
      @list = Snowflake::CustomAttributes::List.get(@test_node, 'list')      
    end

    it "Calls the given block once for each element in the set, passing the element as parameter. (collect)" do
      @list.collect { |value| 'figs!' }.should == ['figs!', 'figs!', 'figs!']
    end

    it "Calls the given block once for each element in the set, passing the element as parameter. (map)" do
      @list.map { |value| 'figs!' }.should == ['figs!', 'figs!', 'figs!']
    end
  end # #collect

  describe "#collect!" do
    before(:each) do
      @test_node.send_command( 'list', :lpush, 'baz' )
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )
      @list = Snowflake::CustomAttributes::List.get(@test_node, 'list')      
    end
    
    it "Invokes the block once for each element of self, replacing the element with the value returned by block. (collect!)" do
      @list.collect! { |value| 'figs!' }
      @list.reload
      @list.should == ['figs!', 'figs!', 'figs!']
    end

    it "Invokes the block once for each element of self, replacing the element with the value returned by block. (map!)" do
      @list.map! { |value| 'figs!' }
      @list.reload
      @list.should == ['figs!', 'figs!', 'figs!']
    end
  end # #collect!

  describe "Compact" do
    before(:each) do
      @test_node.send_command( 'list', :lpush, nil )
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, nil )
      @test_node.send_command( 'list', :lpush, nil )
      @test_node.send_command( 'list', :lpush, 'foo' )
      @list = Snowflake::CustomAttributes::List.get(@test_node, 'list')      
    end

    it "Returns a copy of self with all nil elements removed." do
      @list.compact.should == ['foo', 'bar']
    end

    it "Removes nil elements from array. Returns nil if no changes were made." do
      @list.compact!
      @list.reload
      @list.should == ['foo', 'bar']
    end
  end

  describe "#[]" do
    before(:each) do
      @test_node.send_command( 'list', :lpush, 'baz' )
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )
      @list = Snowflake::CustomAttributes::List.get(@test_node, 'list')      
    end

    it "retrieves a single element by its index" do
      @list[0].should == 'foo'
      @list[1].should == 'bar'
      @list[2].should == 'baz'
    end

    it "returns nil for an out of range index" do
      @list[3].should be_nil
    end

    it "returns index from the end via negative index" do
      @list[-1].should == 'baz'
      @list[-2].should == 'bar'
      @list[-3].should == 'foo'
    end

    it "slices the list from a start index for a specific length" do
      @list[1,2].should == ['bar', 'baz']
    end

    it "slices the list using a range" do
      @list[0..2].should == ['foo', 'bar', 'baz']
      @list[1..2].should == ['bar', 'baz']
    end
  end

  describe "#[]=" do
    before(:each) do
      @test_node.send_command( 'list', :lpush, 'baz' )
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )
      @list = Snowflake::CustomAttributes::List.get(@test_node, 'list')      
    end

    it "retrieves a single element by its index" do
      @list[0].should == 'foo'
      @list[0] = 'bob'
      @list = Snowflake::CustomAttributes::List.get(@test_node, 'list')      
      @list[0].should == 'bob'
    end

    it "raises ArgumentError for an out of range index" do
      lambda {
        @list[3] = 'bob'
      }.should raise_error(ArgumentError)
    end

    it "returns nil for an out of range slice" do
      pending
    end

    it "slices the list from a start index for a specific length" do
      @list[1, 2] = ['two', 'three']
      @list.reload
      @list.should == ['foo', 'two', 'three']
    end

    it "raises ArgumentError when providing a replacement slice larger than the slice taken" do
      lambda {
        @list[1, 2] = ['two', 'three', 'four']
      }.should raise_error(ArgumentError)
    end

    it "slices the list using a range" do
      @list[1..2] = ['two', 'three']
      @list.reload
      @list.should == ['foo', 'two', 'three']
    end
  end

  describe "#clear" do
    it "clears all elements from an existing list" do
      @test_node.send_command( 'list', :lpush, 'baz' )
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.clear
      list.reload
      list.should be_empty
    end

    it "does nothing when clearing multiple elements from a nonexistant list" do
      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')
      list.clear
      list.reload
      list.should be_empty
      @test_node.send_command( 'list', :exists ).should be_false
    end

    it "fails to clears all elements from an existing list when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      @test_node2.send_command( 'list', :lpush, 'baz' )
      @test_node2.send_command( 'list', :lpush, 'bar' )
      @test_node2.send_command( 'list', :lpush, 'foo' )
      list = Snowflake::CustomAttributes::List.get(@test_node2, 'list')
      
      lambda {
        list.clear
      }.should raise_error(Snowflake::NotPersisted)
    end
  end # #clear

  describe "#==" do
    describe "A == B" do
      it "returns true when comparing two lists with identical contents" do
        @test_node.send_command( 'list1', :lpush, 'bar' )
        @test_node.send_command( 'list1', :lpush, 'foo' )

        @test_node.send_command( 'list2', :lpush, 'bar' )
        @test_node.send_command( 'list2', :lpush, 'foo' )

        list1 = Snowflake::CustomAttributes::List.get(@test_node, 'list1')
        list2 = Snowflake::CustomAttributes::List.get(@test_node, 'list2')
        list1.should == list2
      end

      it "returns true when comparing a list with Ruby Array, with identical contents" do
        @test_node.send_command( 'list1', :lpush, 'bar' )
        @test_node.send_command( 'list1', :lpush, 'foo' )

        list = Snowflake::CustomAttributes::List.get(@test_node, 'list1')
        list.should == ['foo', 'bar']
      end
    end # A == B

    describe "A != B" do
      it "returns false when comparing two lists with non-identical contents" do
        @test_node.send_command( 'list1', :lpush, 'bar' )
        @test_node.send_command( 'list1', :lpush, 'foo' )

        @test_node.send_command( 'list2', :lpush, 'foo' )

        list1 = Snowflake::CustomAttributes::List.get(@test_node, 'list1')
        list2 = Snowflake::CustomAttributes::List.get(@test_node, 'list2')
        list1.should_not == list2
      end

      it "returns false when comparing a list with Ruby Array, with non-identical contents" do
        @test_node.send_command( 'list1', :lpush, 'bar' )
        @test_node.send_command( 'list1', :lpush, 'foo' )

        list = Snowflake::CustomAttributes::List.get(@test_node, 'list1')
        list.should_not == ['foo']
      end
    end # A != B

  end # #==

  describe "#each" do
    it "iterates over each element in an existing list" do
      @test_node.send_command( 'list', :lpush, 'baz' )
      @test_node.send_command( 'list', :lpush, 'bar' )
      @test_node.send_command( 'list', :lpush, 'foo' )

      list = Snowflake::CustomAttributes::List.get(@test_node, 'list')

      values = []
      list.each do |value|
        values << value
      end

      values.sort.should == ['bar', 'baz', 'foo']
    end
  end # #each
=begin
&
intersection
|
union
-
difference
=end

end