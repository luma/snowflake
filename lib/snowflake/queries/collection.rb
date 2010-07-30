module Snowflake
  module Queries
    class Collection
    	attr_reader :element_klass, :operand

    	def initialize( element_klass, operand )
    		@element_klass, @operand = element_klass, operand
    	end

      def all
        @all ||= @element_klass.get_many( keys )
      end

    	def each
    		all.each do |element|
    			yield element
    		end
    	end
    	
    	def first
    	  if elements_loaded?
      	  all.first
  	    else
  	      @element_klass.get( keys.first )
	      end
  	  end
  	  
  	  def last
    	  if elements_loaded?
      	  all.last
  	    else
  	      @element_klass.get( keys.last )
	      end
	    end

      def length
        keys.length
      end

      def include?( key )
        keys.include?( key.to_s )
      end
      
      def get( key )
        unless include?( key )
          return nil
        end

        if elements_loaded?
          all.select {|element| element.key == key.to_s }.first
        else
          @element_klass.get( key )
        end
      end

    	# return a new collection that consists of this collection and the other one
    	def &(options)
        filters = Operand.from_options( @element_klass, options )
    		Collection.new( @element_klass, Operations::AndOperation.new( @operand, *filters ) )
    	end
    	alias :and :&

    	# return a new collection that consists of this collection or the other one	
    	def |(options)
  	    filters = Operand.from_options( @element_klass, options )
  	    
  	    inner_op =  if filters.length > 1
              	      Operations::AndOperation.new( *filters )
            	      else
            	        filters.first
                    end

    		Collection.new( @element_klass, Operations::OrOperation.new( @operand, inner_op ) )
    	end
    	alias :or :|

    	def reload
    	  @keys = nil
    	  @all = nil
      end

    	private

    	def keys_loaded?
    	  @keys != nil
  	  end

      def elements_loaded?
        @all != nil
      end

    	def keys
    		@keys ||= @operand.eval.execute
    	end
    end
  end # module Queries
end # module Snowflake