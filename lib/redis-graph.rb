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

# Speed boost, and reduced memory leaks from standard ruby threading (on Ruby < 1.9), if it's available: use it.
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

  class InvalidTypeError < RedisGraphError
  end

  class InvalidAttributeError < RedisGraphError
  end

  class DynamicAttributeError < RedisGraphError
  end

  class NameInUseError < InvalidAttributeError
  end

  class NotPersisted < RedisGraphError
  end

  class MissingPropertyError < RedisGraphError
  end

  class MissingKeyPropertyError < RedisGraphError
  end

  class NotFoundError < RedisGraphError
  end

  class NodeKeyAlreadyExistsError < RedisGraphError
  end

  class AliasInUseError < RedisGraphError
  end

  def self.connect(*args)
    options = args
    connection = nil
  end

  def self.connection
    # @todo fix Redis Namespacing
    #thread[:connection] ||= Redis::Namespace.new(namespace, :redis => redis)
    thread[:connection] ||= Redis.new(*options)
  end

  def self.connection=(redis)
    thread[:connection] = redis
  end

  def self.namespace
    thread[:namespace] ||= :redis_graph
  end

  def self.namespace=(n)
    thread[:namespace] = n
  end

  def self.options
    @options ||= []
  end

  def self.options=(options)
    @options = options
  end

  def self.flush_db
    connection.flushdb
  end

  def self.thread
    Thread.current[:redis_graph] ||= {}
  end
  
  # @todo I'm not thrilled about this being public. however, too many places need it and at least I can be sure everyone is generating keys of the same form.
  # @api private
  def self.key(*segments)
    segments.join(':')
  end
  
  autoload :Attribute, 'redis-graph/element/attribute'

  module Attributes
    dir = File.join(Pathname(__FILE__).dirname.expand_path + 'redis-graph/element/attributes/')

    # Make our custom types available in a more convienant way
    autoload :Boolean,  dir + 'boolean'
    autoload :Dynamic,  dir + 'dynamic'
    autoload :Guid,     dir + 'guid'
    autoload :Integer,  dir + 'integer'
    autoload :String,   dir + 'string'
  end
  
  autoload :CustomAttribute,  'redis-graph/element/custom_attribute'
  
  module CustomAttributes
    dir = File.join(Pathname(__FILE__).dirname.expand_path + 'redis-graph/element/custom_attributes/')

    # Make our custom types available in a more convienant way
    autoload :Counter,  dir + 'counter'
    autoload :Set,      dir + 'set'
    autoload :List,     dir + 'list'
  end
end # module RedisGraph

# Convienant place to store this
unless defined?(Infinity)
  Infinity = 1.0/0
end

dir = File.join(Pathname(__FILE__).dirname.expand_path + 'redis-graph/')

require dir + 'element'
require dir + 'element/model'
require dir + 'element/attributes'
require dir + 'element/plugins/attributes'
require dir + 'element/plugins/class_methods'
require dir + 'element/plugins/hooks'
require dir + 'element/plugins/naming'
require dir + 'element/plugins/serialisers'
require dir + 'element/plugins/validations'

require dir + 'element/plugins/custom_attributes'
#require dir + 'element/plugins/counters'
#require dir + 'element/plugins/sets'

require dir + 'node'
# require dir + 'node/descendants'
# require dir + 'node/properties'
# require dir + 'node/class_methods'

# ActiveModel Compatability
# require dir + 'node/active_model_compatability/base'
# require dir + 'node/active_model_compatability/validations'

