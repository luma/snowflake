unless $:.include?( File.dirname(__FILE__) ) || $:.include?( File.expand_path( File.dirname(__FILE__) ) )
  $:.unshift(File.dirname(__FILE__))
end

require 'set'
require 'pathname'
require 'json'

require 'active_support'
require 'active_support/inflector'
require 'active_model'

require 'redis'
#require 'redis/namespace'
require 'uuidtools'

# Speed boost, and reduced memory leaks from standard ruby threading, if it's available: use it.
begin
  require 'fastthread'
rescue LoadError
  # fastthread not installed
end

module RedisGraph
  VERSION = '0.0.1'

  class RedisGraphError < StandardError
  end

  class NotImplementedError < RedisGraphError
  end

  class InvalidPropertyError < RedisGraphError
  end

  class PropertyNameInUseError < InvalidPropertyError
  end

  class MissingPropertyError < RedisGraphError
  end

  class MissingKeyPropertyError < RedisGraphError
  end

  class NodeNotFoundError < RedisGraphError
  end

  class NodeKeyAlreadyExistsError < RedisGraphError
  end

  class AliasInUseError < RedisGraphError
  end

  class InvalidRelationshipType < RedisGraphError
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
  
  # @todo I'm not thrilled about this being public. however, too many places need it and at least I can be sure everyone is generating keys of the same form.
  # @api private
  def self.key(*segments)
    segments.join(':')
  end
  
#  autoload :Node

#  autoload :IdentityMap, 'redis-graph/identity_map'
  autoload :PropertyPrototype, 'redis-graph/property_prototype'
  autoload :Property, 'redis-graph/property'

  module Node
#    autoload :Descentants, 'node/descendants'
#    autoload :Properties, 'node/properties'
#    autoload :ClassMethods, 'node/class_methods'
#    autoload :Relationships, 'node/relationships'
  end
  
  module Properties
    dir = File.join(Pathname(__FILE__).dirname.expand_path + 'redis-graph/properties/')

    # Make our custom types available in a more convienant way
    autoload :Boolean,         dir + 'boolean'
    autoload :Counter,         dir + 'counter'
    autoload :Guid,            dir + 'guid'
    autoload :Hash,            dir + 'hash'
    autoload :Integer,         dir + 'integer'
    autoload :List,            dir + 'list'
    autoload :Set,             dir + 'set'
    autoload :String,          dir + 'string'
  end
end # module RedisGraph

# Convienant place to store this
unless defined?(Infinity)
  Infinity = 1.0/0
end


dir = File.join(Pathname(__FILE__).dirname.expand_path + 'redis-graph/')

require dir + 'node'
require dir + 'node/descendants'
require dir + 'node/properties'
require dir + 'node/class_methods'

# ActiveModel Compatability
require dir + 'node/active_model_compatability/base'
require dir + 'node/active_model_compatability/validations'

#require dir + 'properties/boolean'
#require dir + 'properties/counter'
#require dir + 'properties/hash'
#require dir + 'properties/list'
#require dir + 'properties/set'
#require dir + 'properties/string'
#require dir + 'properties/integer'
#require dir + 'properties/guid'
