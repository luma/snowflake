require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Node do
  describe "indices" do    
    before(:each) do
      @all = []
      10.times do |i|
        @all << TestNode.create(:name => "bob #{i}", :mood => 'Awesome')
      end
    end

    describe "All" do
      before :all do
        @all_index = TestNode.indices[:all]
      end

      it "has an 'all' index" do
        @all_index.is_a?(::Snowflake::Index).should be_true
      end

      it "includes all nodes of that type" do
        @all_index.length.should == 10
        @all_index.all.sort.should == @all.sort
      end
      
      it "can indicate whether a node with a specific id exists in the index" do
        10.times do |i|
          @all_index.should include( @all[i].key )
        end

        @all_index.should_not include( "does not exist" )
      end

      it "when deleting nodes they are removed from the index" do
        @all_index.should include( @all.first.key )
        @all.first.destroy
        @all_index.should_not include( @all.first.key )
      end

      it "updates the index when changing keys" do
        old_key = @all.last.key
        @all.last.key = "something_else"
        @all.last.save.should be_true
        @all_index.should_not include( old_key )
        @all_index.should include( "something_else" )
      end
    end
  end
end
