require 'rubygems'
require 'spec'
require 'ruby-debug'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'snowflake'

class TestNode
  include Snowflake::Node

  attribute :name,         String, :key => true, :index => true
  attribute :age,          Integer, :index => true
  attribute :mood,         String, :required => true, :index => true
  attribute :description,  String
  attribute :enabled,      ::Snowflake::Attributes::Boolean, :default => false

#  counter :visits      # <-- native Redis Counter
  set :tags, :index => true            # <-- native Redis Set
#  list :awards         # <-- native Redis List
  # @TODO: Hash

  # validates_presence_of :name
  # validates_presence_of :mood
end

class TestNodeWithCustomAttributes
  include Snowflake::Node

  attribute :name,         String, :key => true
  attribute :age,          Integer
  attribute :mood,         String, :required => true
  attribute :description,  String

  # validates_presence_of :name
  # validates_presence_of :mood

  counter :counter
  set :stuff, :index => true
end

class TestNodeThatAllowsDynamicAttributes
  include Snowflake::Node

  allow_dynamic_attributes!
  attribute :name,         String, :key => true

end

Spec::Runner.configure do |config|
  config.mock_with :mocha

  config.before :suite do
    puts "Starting indexer for testing..."
    
    indexer_path = File.expand_path( File.dirname(__FILE__) + '/../../snowflake-indexer/' )
    puts "cd #{indexer_path} && ./bin/snowflake-indexer start"
    `cd #{indexer_path} && ./bin/snowflake-indexer start`
  end 

  config.after :each do
    Snowflake.log_level = Logger::DEBUG
    Snowflake.connect
    Snowflake.flush_db
  end

  config.after :suite do
    puts "Shutting down indexer for testing..."
    indexer_path = File.expand_path( File.dirname(__FILE__) + '/../../snowflake-indexer/' )
    puts "cd #{indexer_path} && ./bin/snowflake-indexer stop"
    `cd #{indexer_path} && ./bin/snowflake-indexer stop`
  end
end