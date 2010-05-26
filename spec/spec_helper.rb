require 'rubygems'
require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'redis-graph'

class TestNode
  include RedisGraph::Node

  property :name,         String, :id => true
  property :age,          Integer
  property :mood,         String
  property :description,  String
  property :enabled,      ::RedisGraph::Properties::Boolean

  property :visits,       ::RedisGraph::Properties::Counter       # <-- native Redis Counter
  property :tags,         ::RedisGraph::Properties::Set           # <-- native Redis Set
  property :awards,       ::RedisGraph::Properties::List          # <-- native Redis List
  # @TODO: Hash

  #edge :
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
end