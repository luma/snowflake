module Snowflake
  class Index
    attr_reader :name, :key, :element_klass

    def initialize( name, element_klass )
      @name, @element_klass = name.to_s, element_klass
      @key = element_klass.meta_key_for( 'indices', @name )
    end

    def add( id )
      Snowflake.connection.sadd( @key, id )
    end

    def delete(id )
      Snowflake.connection.srem( @key, id )
    end
    
    def include?( id )
      Snowflake.connection.sismember( @key, id )
    end

    def length
      Snowflake.connection.scard( @key )
    end

    def ids
      Snowflake.connection.smembers( @key )
    end
    
    # @todo indices should be combinable with union, difference, and intersection

    def all
      element_klass.get_many( ids )
    end
  end # class Index
end # module Snowflake