require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  describe "indices" do    
    describe "Modifying" do
      before(:each) do
        Snowflake.flush_db

        @all = []
        2.times do |i|
          @all << TestNode.create(:name => "bob #{i}", :mood => 'Awesome')
        end

        # Wait for the indexer to catch up
        sleep 2

        @all_from_index = TestNode.all
      end

      it "when deleting nodes they are removed from the index" do
        @all_from_index.should include( @all.first.key )
        @all.first.destroy
        
        # Wait for the indexer to catch up
        sleep 1

        @all_from_index.should_not include( @all.first.key )
      end
    end

    describe "All" do
      before(:all) do
        Snowflake.flush_db

        @all = []
        5.times do |i|
          @all << TestNode.create(:name => "bob #{i}", :mood => 'Awesome')
        end

        # Wait for the indexer to catch up
        sleep 5

        @all_from_index = TestNode.all
      end

      it "includes all nodes of that type" do
        # debugger
        debugger
        @all_from_index.length.should == @all.length
        @all_from_index.all.sort.should == @all.sort
      end
      
      it "can indicate whether a node with a specific id exists in the index" do
        @all.length.times do |i|
          @all_from_index.should include( @all[i].key )
        end

        @all_from_index.should_not include( "does not exist" )
      end

      it "updates the index when changing keys" do
        old_key = @all.last.key
        debugger
        @all.last.key = "something_else"

        # Wait for the indexer to catch up
        sleep 2

        @all_from_index.should_not include( old_key )
        @all_from_index.should include( "something_else" )
      end
    end
    
    describe "#first" do
      before :all do
        Snowflake.flush_db

        @test_node2 = TestNode.create(:name => 'jim', :mood => 'Sleepy')
      end

      it "returns the first element" do
        TestNode.first.should == @test_node
      end

      it "returns the first element with filtering" do
        TestNode.first(:mood => 'Sleepy').should == @test_node2
      end
    end

    describe "#last" do
      before :all do
        Snowflake.flush_db        
        @test_node2 = TestNode.create(:name => 'jim', :mood => 'Sleepy')
      end

      it "returns the last element" do
        TestNode.last.should == @test_node2
      end

      it "returns the last element with filtering" do
        TestNode.last(:mood => 'Awesome').should == @test_node
      end
    end

    describe "#random" do
      before :all do
        Snowflake.flush_db
        @test_node2 = TestNode.create(:name => 'jim', :mood => 'Sleepy')
      end

      it "returns a random element" do
        [@test_node, @test_node2].should include(TestNode.random)
      end

      it "returns the random element with filtering" do
        TestNode.random(:mood => 'Awesome').should == @test_node
      end
    end
    
  end # indices
end
