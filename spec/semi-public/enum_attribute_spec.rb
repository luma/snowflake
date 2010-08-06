require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Attributes::Enum do
  before :all do
    @t = Snowflake::Attributes::Enum.new(TestNode, :foo, { :values => [:one, 'two', 'three', :four, 'five'] })
  end

  describe "#new" do
    it "converts all values to symbols" do
      for value in @t.options[:values]
        value.should be_a(Symbol)
      end
    end
  end

  describe "#dump" do
    it "returns the (one based) index of the particular value from the :values option" do
      @t.dump( :one ).should == 1
      @t.dump( :two ).should == 2
    end

    it "returns nil when the value is nil" do
      @t.dump( nil ).should be_nil
    end
  end

  describe "#typecast" do
    it "typecasts nil to the default value" do
      @t.typecast( nil ).should == @t.default
    end

    it "typecasts String values to symbols" do
      @t.typecast( 'two' ).should == :two
    end

    it "does nothing to Symbol values" do
      @t.typecast( :two ).should == :two
    end

    it "raises an ArgumentError when typecasting an invalid enum value" do
      lambda {
        @t.typecast( :foo )
      }.should raise_error(ArgumentError)
    end

    it "tries to typecast an Integer value by using it as an index into the :values option" do
      @t.typecast( 1 ).should == :one
    end
    
    it "raises an ArgumentError when attempting to typecast an Integer that is out of range" do
      lambda {
        @t.typecast( 0 )
      }.should raise_error(ArgumentError)

      lambda {
        @t.typecast( 6 )
      }.should raise_error(ArgumentError)
    end
  end
end