require 'rubygems'
require 'spec'
require 'ruby-debug'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'redis-graph'

class TestNode
  include RedisGraph::Node

  attribute :name,         String, :key => true
  attribute :age,          Integer
  attribute :mood,         String
  attribute :description,  String
  attribute :enabled,      ::RedisGraph::Attributes::Boolean

#  counter :visits      # <-- native Redis Counter
#  set :tags            # <-- native Redis Set
#  list :awards         # <-- native Redis List
  # @TODO: Hash

  validates_presence_of :name
end

Spec::Runner.configure do |config|
  config.mock_with :mocha

  config.after :each do 
    RedisGraph.flush_db
  end
end