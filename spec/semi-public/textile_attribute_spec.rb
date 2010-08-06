require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Snowflake::Attributes::Textile do
  before :all do
    @textile = <<-EOS
h1. Hello World

Some text is here
* first
* second
* third
EOS

    @t = Snowflake::Attributes::Textile.new(TestNode, :foo, {})
    @t2 = @t.typecast(@textile)
  end

  describe "#new" do
    it "dumps a Textile Attribute to textile" do
      t = Snowflake::Attributes::Textile.new(TestNode, :foo, {:simple => true})
      t.options[:restrictions].should == [:sanitize_html, :lite_mode]
    end
  end

  describe "#get" do
    it "gets the Textile attribute" do
      Snowflake::Attribute.get("Textile").should_not be_nil
    end
  end
  
  describe "#typecast" do
    it "typecasts textile to a RedCloth object" do
      @t2.is_a?(RedCloth::TextileDoc).should be_true
    end

    it "can convert a typecast Textile Attribute to html" do
      # The + "\n" on the LHS is just because our HEREDOC will have that appended to it.
      (@t2.to_html + "\n").should == <<-EOS
<h1>Hello World</h1>
<p>Some text is here</p>
<ul>
\t<li>first</li>
\t<li>second</li>
\t<li>third</li>
</ul>
EOS
    end
  end

  describe "#dump" do
    it "dumps a Textile Attribute to textile" do
      @t.dump( @t2 ).should == @textile
    end
  end
end
