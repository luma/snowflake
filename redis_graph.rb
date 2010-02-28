$:.unshift File.expand_path(File.dirname(__FILE__))

require 'set'
require 'extlib'
require 'pathname'
require 'json'

dir = Pathname(__FILE__).dirname.expand_path / 'redis_graph'
require dir / 'support/chainable'
require dir / 'support/descendant_depends'

module RedisGraph
  class RedisGraphError < StandardError
  end

  def self.connection
    @connection ||= Redis.new
  end
  
  def self.connection=(redis)
    @connection = redis
  end

  autoload :IdentityMap, 'redis_graph/identity_map'
#  autoload :Node, 'redis_graph/node'
#  autoload :Relationship, 'redis_graph/relationship'
  autoload :Property, 'redis_graph/property'

  module Nodes
#    autoload :Properties, 'nodes/properties'
#    autoload :Relationships, 'nodes/relationships'
  end
end # module RedisGraph

#dir = Pathname(__FILE__).dirname.expand_path / 'redis_graph'

require dir / 'node'
require dir / 'nodes/properties'
#require dir / 'nodes/relationships'
#require dir / 'relationship'