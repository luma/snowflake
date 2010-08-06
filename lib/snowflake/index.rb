module Snowflake
  class Index
    attr_reader :name, :key, :element_klass

    def initialize( name, element_klass )
      @name, @element_klass = name.to_s, element_klass
      @key = element_klass.meta_key_for( 'indices', @name )
    end

    def add( id, sub_key = nil)
      if sub_key.respond_to?(:each)
        sub_key.each do |k|
          Snowflake.connection.sadd( key_for(k), id )
        end
      else
        Snowflake.connection.sadd( key_for(sub_key), id )
      end
    end

    def delete(id, sub_key = nil)
      if sub_key.respond_to?(:each)
        sub_key.each do |k|
          Snowflake.connection.srem( key_for(k), id )
        end
      else
        Snowflake.connection.srem( key_for(sub_key), id )
      end
    end
    
    def modify(id, old_sub_key, new_sub_key)
      delete( id, old_sub_key )
      add( id, new_sub_key )
    end

    def include?( id, sub_key = nil)
      Snowflake.connection.sismember( key_for(sub_key), id )
    end

    def length(sub_key = nil)
      Snowflake.connection.scard( key_for(sub_key) )
    end

    def ids(sub_key = nil)
      Snowflake.connection.smembers( key_for(sub_key) )
    end

    def random
      element_key = Snowflake.connection.srandmember( @key )
      element_key == nil ? nil : element_klass.get( element_key )
    end

    # @todo indices should be combinable with union, difference, and intersection

    def all(sub_key = nil)
      element_klass.get_many( ids(sub_key) )
    end

    protected

    def key_for(sub_key = nil)
      if sub_key == nil
        @key
      else
        @element_klass.meta_key_for( 'indices', @name, sub_key )
      end
    end
  end # class Index
end # module Snowflake