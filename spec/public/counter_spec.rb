require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe RedisGraph::Counter do
  before(:all) do
    @test_node = TestNode.create(:name => 'rolly', :mood => 'Awesome')
  end

  describe "#get" do
    it "retrieves a counter by name" do
      @test_node.send_command( 'counter', :set, 5 )
      counter = RedisGraph::Counter.get(@test_node, 'counter')
      counter.to_i.should == 5
    end

    it "retrieves a counter with the default value of 0 if no counter exists for a specific name" do
      counter = RedisGraph::Counter.get(@test_node, 'bob').to_i.should == 0
    end
  end
  
  describe "#set" do
    it "sets the counter's value in Redis" do
      counter = RedisGraph::Counter.get(@test_node, 'counter')
      counter.to_i.should == 0
      counter.replace(5)

      RedisGraph::Counter.get(@test_node, 'counter').to_i.should == 5
    end
    
    it "fails to sets the counter's value in Redis when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      counter = RedisGraph::Counter.get(@test_node2, 'counter')
      
      lambda {
        counter.replace(5)
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end

  describe "incriments atomically" do
    before(:each) do
      @counter = RedisGraph::Counter.get(@test_node, 'counter')
      @counter.to_i.should == 0
    end

    it "incriments (#incriment!) the counter by 1" do
      @counter.incriment!

      RedisGraph::Counter.get(@test_node, 'counter').to_i.should == 1
    end

    it "incriments (#incr!) the counter by 1" do
      @counter.incr!

      RedisGraph::Counter.get(@test_node, 'counter').to_i.should == 1
    end

    it "incriments the counter by n" do
      @counter.incriment!(13)

      RedisGraph::Counter.get(@test_node, 'counter').to_i.should == 13
    end

    it "fails to incriments (#incriment!) the counter by 1 when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      counter = RedisGraph::Counter.get(@test_node2, 'counter')
      
      lambda {
        counter.incriment!
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end
  
  describe "decriments atomically" do
    before(:each) do
      @counter = RedisGraph::Counter.get(@test_node, 'counter')
      @counter.to_i.should == 0
    end

    it "decriment (#decriment!) the counter by 1" do
      @counter.decriment!

      RedisGraph::Counter.get(@test_node, 'counter').to_i.should == -1
    end

    it "decriment (#decr!) the counter by 1" do
      @counter.decr!

      RedisGraph::Counter.get(@test_node, 'counter').to_i.should == -1
    end

    it "decriment (#decriment!) the counter by n" do
      @counter.decriment!(13)

      RedisGraph::Counter.get(@test_node, 'counter').to_i.should == -13
    end

    it "fails to decriment (#decriment!) the counter by 1 when the element is not persisted" do
      @test_node2 = TestNode.new(:name => 'bob', :mood => 'Awesome')

      counter = RedisGraph::Counter.get(@test_node2, 'counter')
      
      lambda {
        counter.decriment!
      }.should raise_error(RedisGraph::NotPersisted)
    end
  end
  
  # Mimic an integer
  describe "Behaves like an Integer" do
    before(:each) do
      @counter = RedisGraph::Counter.get(@test_node, 'counter')
      @counter.replace(10)
      @counter.to_i.should == 10
    end

    it "behaves like an Integer during addition" do
      (@counter + 2).should == @counter.to_i + 2
    end

    it "behaves like an Integer during subtraction" do
      (@counter - 2).should == @counter.to_i - 2
    end

    it "behaves like an Integer during multiplication" do
      (@counter * 2).should == @counter.to_i * 2
    end

    it "behaves like an Integer during division" do
      (@counter / 2).should == @counter.to_i / 2
    end

    it "behaves like an Integer during #==" do
      (@counter == 10).should == (@counter.to_i == 10)
      (@counter == 2).should == (@counter.to_i == 2)
    end

    it "behaves like an Integer during #<" do
      (@counter < 11).should == (@counter.to_i < 11)
      (@counter < 9).should == (@counter.to_i < 9)
    end

    it "behaves like an Integer during #>" do
      (@counter > 11).should == (@counter.to_i > 11)
      (@counter > 9).should == (@counter.to_i > 9)
    end

    it "behaves like an Integer during #<=>" do
      (@counter <=> 9).should == (@counter.to_i <=> 9)
      (@counter <=> 10).should == (@counter.to_i <=> 10)
      (@counter <=> 11).should == (@counter.to_i <=> 11)
    end

    it "behaves like an Integer during #to_s" do
      (@counter > 11).should == (@counter.to_i > 11)
    end
  end
end