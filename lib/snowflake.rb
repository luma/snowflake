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

module Snowflake

  class SnowflakeError < StandardError
  end

  class NotImplementedError < SnowflakeError
  end

  class InvalidTypeError < SnowflakeError
  end

  class InvalidAttributeError < SnowflakeError
  end

  class DynamicAttributeError < SnowflakeError
  end

  class NameInUseError < InvalidAttributeError
  end

  class NotPersisted < SnowflakeError
  end

  class MissingPropertyError < SnowflakeError
  end

  class MissingKeyPropertyError < SnowflakeError
  end

  class NotFoundError < SnowflakeError
  end

  class NodeKeyAlreadyExistsError < SnowflakeError
  end

  class AliasInUseError < SnowflakeError
  end

  class OutOfDateError < SnowflakeError
  end

  def self.connect(*args)
    handle_passenger_forking
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
  
  # Construct an element key from +segments+.
  #
  # @todo I'm not thrilled about this being public. however, too many places need it and at least I can be sure everyone is generating keys of the same form.
  #
  # @api semi-public
  def self.key(*segments)
    segments.join(':')
  end

  # Construct a meta key (for storing metainfo regarding elements) for +segments+.
  #
  # @todo I'm not thrilled about this being public. however, too many places need it and at least I can be sure everyone is generating keys of the same form.
  #
  # @api semi-public
  def self.meta_key(*segments)
    segments.join('::')
  end
  
  autoload :Attribute, 'snowflake/element/attribute'

  module Attributes
    dir = File.join(Pathname(__FILE__).dirname.expand_path + 'snowflake/element/attributes/')

    # Make our custom types available in a more convienant way
    autoload :Boolean,  dir + 'boolean'
    autoload :Dynamic,  dir + 'dynamic'
    autoload :Guid,     dir + 'guid'
    autoload :Integer,  dir + 'integer'
    autoload :String,   dir + 'string'
  end
  
  autoload :CustomAttribute,  'snowflake/element/custom_attribute'
  
  module CustomAttributes
    dir = File.join(Pathname(__FILE__).dirname.expand_path + 'snowflake/element/custom_attributes/')

    # Make our custom types available in a more convienant way
    autoload :Counter,  dir + 'counter'
    autoload :Set,      dir + 'set'
    autoload :List,     dir + 'list'
  end
  
  protected
  
  # http://www.modrails.com/documentation/Users%20guide%20Nginx.html#_smart_spawning_gotcha_1_unintential_file_descriptor_sharing
  def self.handle_passenger_forking
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked
          # We're in smart spawning mode.
          thread[:connection] = Redis.new(*options)
        else
          # We're in conservative spawning mode. We don't need to do anything.
        end
      end
    end
  end
end # module Snowflake

# Convienant place to store this
unless defined?(Infinity)
  Infinity = 1.0/0
end

dir = File.join(Pathname(__FILE__).dirname.expand_path + 'snowflake/')

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

