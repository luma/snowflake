unless $:.include?( File.dirname(__FILE__) ) || $:.include?( File.expand_path( File.dirname(__FILE__) ) )
  $:.unshift(File.dirname(__FILE__))
end

require 'set'
require 'pathname'
require 'json'

require 'active_support'
require 'active_support/hash_with_indifferent_access'
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

begin
  # SystemTimer is preferable to the standard Ruby timeout library on Ruby 1.8.x. This is
  # only true assuming we aren't running on jRuby or Rubinius.
  #   http://ph7spot.com/articles/system_timer  
  if !defined?(RUBY_ENGINE) || (RUBY_ENGINE == 'ruby' && RUBY_VERSION < '1.9.0')
    require 'system_timer'
  else
    require 'timeout'
  end
rescue LoadError => e
  # system_timer not installed (or not needed)
  require 'timeout'
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

  class CustomAttributeError < SnowflakeError
  end

  class CouldNotPersistCustomAttributeError < CustomAttributeError
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

  def self.connect(opts = {})
    handle_passenger_forking
    @options = opts
    connection = nil
  end

  def self.connection
    # @todo fix Redis Namespacing
    #thread[:connection] ||= Redis::Namespace.new(namespace, :redis => redis)
    thread[:connection] ||= Redis.new(options)
  end

  def self.connection=(redis)
    thread[:connection] = redis
  end

  def self.namespace
    thread[:namespace] ||= :snowflake
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
    Thread.current[:snowflake] ||= {}
  end

  autoload :Index,     'snowflake/index'
  autoload :Attribute, 'snowflake/attribute'

  module Attributes
    dir = File.join(Pathname(__FILE__).dirname.expand_path + 'snowflake/attributes/')

    # Make our custom types available in a more convienant way
    autoload :Boolean,  dir + 'boolean'
    autoload :Dynamic,  dir + 'dynamic'
    autoload :Guid,     dir + 'guid'
    autoload :Integer,  dir + 'integer'
    autoload :String,   dir + 'string'
    autoload :Text,     dir + 'text'
    autoload :Textile,  dir + 'textile'
  end
  
  autoload :CustomAttribute,  'snowflake/custom_attribute'
  
  module CustomAttributes
    dir = File.join(Pathname(__FILE__).dirname.expand_path + 'snowflake/custom_attributes/')

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

require dir + 'keys'

require dir + 'element'
require dir + 'model'
require dir + 'attributes'
require dir + 'plugins/hooks'
require dir + 'plugins/validations'
require dir + 'plugins/naming'
require dir + 'plugins/attributes'
require dir + 'plugins/custom_attributes'
require dir + 'plugins/dirty'
require dir + 'plugins/serialisers'
require dir + 'plugins/class_methods'
require dir + 'plugins/indices'

require dir + 'node'

