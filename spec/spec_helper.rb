require 'rubygems'
require 'spec'
require 'ruby-debug'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'snowflake'

class TestNode
  include Snowflake::Node

  attribute :name,         String, :key => true
  attribute :age,          Integer
  attribute :mood,         String
  attribute :description,  String
  attribute :enabled,      ::Snowflake::Attributes::Boolean, :default => false

#  counter :visits      # <-- native Redis Counter
#  set :tags            # <-- native Redis Set
#  list :awards         # <-- native Redis List
  # @TODO: Hash

  validates_presence_of :name
end

class TestNodeWithCustomAttributes
  include Snowflake::Node

  attribute :name,         String, :key => true
  attribute :age,          Integer
  attribute :mood,         String
  attribute :description,  String

  validates_presence_of :name

  counter :counter
  set :stuff
end

class TestNodeThatAllowsDynamicAttributes
  include Snowflake::Node

  allow_dynamic_attributes!
  attribute :name,         String, :key => true

  validates_presence_of :name
end

Spec::Runner.configure do |config|
  config.mock_with :mocha

  config.after :each do
    Snowflake.connect
    Snowflake.flush_db
  end
end