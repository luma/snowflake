require 'rubygems'
require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'redis-graph'

describe RedisGraph::Node do
  describe "ActiveModel Compatability" do
    
    it "responds to to_model" do
      TestNode.new.should.respond_to?(:to_model)
    end
    
    # == Responds to <tt>to_key</tt>
    #
    # Returns an Enumerable of all (primary) key attributes
    # or nil if model.persisted? is false
    it "responds to to_key" do
      model.should respond_to(:to_key)

      def model.persisted?() false end
      model.to_key.should be_nil
    end

    # == Responds to <tt>to_param</tt>
    #
    # Returns a string representing the object's key suitable for use in URLs
    # or nil if model.persisted? is false.
    #
    # Implementers can decide to either raise an exception or provide a default
    # in case the record uses a composite primary key. There are no tests for this
    # behavior in lint because it doesn't make sense to force any of the possible
    # implementation strategies on the implementer. However, if the resource is
    # not persisted?, then to_param should always return nil.
    it "responds to to_param" do
      model.should respond_to(:to_param)
      def model.persisted?() false end
      model.to_param.should be_nil
    end

    # == Responds to <tt>valid?</tt>
    #
    # Returns a boolean that specifies whether the object is in a valid or invalid
    # state.
    it "responds to valid?" do
      model.should respond_to(:valid?)
      assert_boolean(model.valid?, 'valid?')
    end

    # == Responds to <tt>persisted?</tt>
    #
    # Returns a boolean that specifies whether the object has been persisted yet.
    # This is used when calculating the URL for an object. If the object is
    # not persisted, a form for that object, for instance, will be POSTed to the
    # collection. If it is persisted, a form for the object will put PUTed to the
    # URL for the object.
    it "responds to persisted?" do
      model.should respond_to(:persisted?)
      assert_boolean(model.persisted?, 'persisted?')
    end

    # == Naming
    #
    # Model.model_name must returns a string with some convenience methods as
    # :human and :partial_path. Check ActiveModel::Naming for more information.
    #
    it "should have a valid model name" do
      model.class.should respond_to(:model_name)

      model_name = model.class.model_name      
      model_name.should be_a_kind_of(String)
      model_name.human.should be_a_kind_of(String)
      model_name.partial_path.should be_a_kind_of(String)
      model_name.singular.should be_a_kind_of(String)
      model_name.plural.should be_a_kind_of(String)
    end

    # == Errors Testing
    #
    # Returns an object that has :[] and :full_messages defined on it. See below
    # for more details.
    #
    # Returns an Array of Strings that are the errors for the attribute in
    # question. If localization is used, the Strings should be localized
    # for the current locale. If no error is present, this method should
    # return an empty Array.
    it "should have a valid errors object" do
      model.should respond_to(:errors)
    end
    
    describe "Errors" do
      it "responds to :[]" do
        model.errors[:hello].should be_a_kind_of(Array)
      end

      # Returns an Array of all error messages for the object. Each message
      # should contain information about the field, if applicable.
      it "responds to :full_messages" do
        model.errors.should respond_to(:full_messages)
      end
      
      it "returns an array when calling #full_messages" do
        model.errors.full_messages.should be_a_kind_of(Array)
      end
    end

    private

      def model
        @model ||= TestNode.new.to_model
      end
      
      def assert_boolean(result, name)
        (result == true || result == false).should(be_true, "#{name} should be a boolean")
      end

  end
end

