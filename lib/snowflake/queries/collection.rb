module Snowflake
  module Queries
    class Collection
    	attr_reader :element_klass, :operation

    	def initialize( element_klass, operation )
    		@element_klass, @operation = element_klass, operation
    	end

    	def each
    		results.each do |result|
    			yield @element_klass.get(result)
    		end
    	end

    	# return a new collection that consists of this collection and the other one
    	def &( collection )
    		# AndOperation.new expects operations or operands, a collection is neither?
    		Collection.new( Operations::AndOperation.new( self, collection ) )
    	end

    	# return a new collection that consists of this collection or the other one	
    	def |( collection )
    		# OrOperation.new expects operations or operands, a collection is neither?
    		Collection.new( Operations::OrOperation.new( self, collection ) )
    	end
	
    	def reload
    	  @results = nil
      end

    	private

    	def results
    		@results ||= @operation.eval(CommandSet.new).execute
    	end
    end
  end # module Queries
end # module Snowflake