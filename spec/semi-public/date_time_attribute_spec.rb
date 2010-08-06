require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Attributes::DateTime do
  before :all do
    @default = '2010-12-25 07:00'
    @t = Snowflake::Attributes::DateTime.new(TestNode, :foo, { :default => '2010-12-25 07:00'})
  end

  describe "#new" do
    it "converts a string default value to a Date" do
      @t.default.should be_a(DateTime)
    end
  end

  describe "#dump" do
    it "dumps to a string" do
      d = DateTime.parse( '2010-12-25 07:00' )
      @t.dump( d ).should == d.to_s
    end
  end

  describe "#typecast" do
    it "typecasts a nil value to the default" do
      @t.typecast( nil ).should == DateTime.parse( @default )
    end

    it "typecasts a DateTime to itself" do
      @date = DateTime.parse( '2010-01-01 12:00' )
      @t.typecast( @date ).should == @date
    end

    it "typecasts a String value, if it can be parsed as a Date" do
      @date = DateTime.parse( '2010-01-01 12:00' )
      @t.typecast( '2010-01-01 12:00' ).should == @date
    end

    it "fails to typecast a String value that isn't a Date" do
      lambda {
        @t.typecast( 'yo' )
      }.should raise_error(ArgumentError)
    end
  end
end