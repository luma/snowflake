module Snowflake
  module Queries
    class Operand
    	def initialize(element_klass, *names)
    	  @key = element_klass.meta_key_for( *names.unshift( 'indices' ) )
    	end

    	def results_size
    	  1
  	  end

    	def to_key
    	  @key# ||= ::UUIDTools::UUID.random_create.to_s
    	end

      # @note top_level is ignore for Operands
    	def eval(cs = nil, top_level = false)
    	  commands = cs != nil ? cs.dup : CommandSet.new
    		commands << format_command( :smembers )
    		commands
    	end
    	
    	# For debugging purposes, think the EXPLAIN statement in SQL
    	def explain(level = 0)
    	  puts "#{[\t*level]}Index on #{name}"
  	  end

    	class << self
    	  # Convert our Hash of filters to an Array, grab the first key/value pair and
    	  # instanciate the Collection with it. This is only necessary as a collect must
    	  # be instanciated with an Operand/Operation.
    	  # @todo This is fugly, we should be able to reduce these steps, or at least add a from_hash method to AndOperation
    	  def from_options(element_klass, options)
      	  operands = []

    	    options.each do |key, value|
      	    unless value.is_a?(Array)
          	  operands << Queries::Operand.new( element_klass, key, value )
        	  else
              operands.concat( value.collect {|v| self.new( element_klass, key, v )  } )
      	    end
  	      end
  	      
  	      operands
  	    end
  	  end

    	private

    	def format_command(command, *parameters)
    		parameters.unshift( to_key ).unshift( command )
    	end
    end
  end # module Queries
end # module Snowflake