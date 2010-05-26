$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'set'
require 'extlib'
require 'pathname'
require 'json'

require 'redis'
#require 'redis/namespace'

# Speed boost, and reduced memory leaks from standard ruby threading, if it's available: use it.
begin
  require 'fastthread'
rescue LoadError
  # fastthread not installed
end

dir = Pathname(__FILE__).dirname.expand_path / 'redis-graph'

module RedisGraph
  VERSION = '0.0.1'

  class RedisGraphError < StandardError
  end

  class InvalidPropertyError < RedisGraphError
  end

  class MissingPropertyError < RedisGraphError
  end

  class MissingIdPropertyError < RedisGraphError
  end

  class NodeNotFoundError < RedisGraphError
  end

  class AliasInUseError < RedisGraphError
  end

  def self.connection
    # @todo fix Redis Namespacing
    #current[:connection] ||= Redis::Namespace.new(namespace, :redis => redis)
    current[:connection] ||= redis
  end

  def self.connection=(redis)
    current[:connection] = redis
  end

  def self.namespace
    current[:namespace] ||= :redis_graph
  end

  def self.namespace=(n)
    current[:namespace] = n
  end

  def self.redis
    current[:redis] ||= Redis.new
  end

  def self.redis=(redis)
    current[:redis] = redis
  end

  def self.current
    Thread.current[:redis_graph] ||= {}
  end

  def self.flush_db
    redis.flushdb
  end

#  autoload :IdentityMap, 'redis-graph/identity_map'
  autoload :PropertyPrototype, 'redis-graph/property_prototype'
  autoload :Property, 'redis-graph/property'

  module Node
#    autoload :Properties, 'node/properties'
#    autoload :Relationships, 'node/relationships'
  end
end # module RedisGraph

require dir / 'node'
require dir / 'node/descendants'
require dir / 'node/properties'
require dir / 'node/class_methods'
#require dir / 'node/relationships'
#require dir / 'relationship'

require dir / 'properties/boolean'
require dir / 'properties/counter'
require dir / 'properties/hash'
require dir / 'properties/list'
require dir / 'properties/set'
require dir / 'properties/string'
require dir / 'properties/integer'