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
  	    elsif !empty?
  	      @element_klass.get( keys.first )
	      else
	        nil
	      end
  	  end
  	  
  	  def last
    	  if elements_loaded?
      	  all.last
  	    elsif !empty?
  	      @element_klass.get( keys.last )
	      else
	        nil
	      end
	    end
	    
	    def random
    	  Collection.new( @element_klass, Operations::RandomOperation.new( @operand ) ).first
      end

      def length
        keys.length
      end

      def empty?
        keys.empty?
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
    	  @command_set = nil
      end

    	def keys
        # @todo this is a little clumsy
    		if @keys == nil
    		  @keys = command_set.execute( @operand.results_size ) || []
    		  
          if Snowflake.log_level == :debug
            explain
          end
  		  end

  		  @keys
    	end 

    	def explain
    	  lines = [
    	    "\nEXPLAIN:",
    	    @operand.explain(1),
    	    "\nRESULTS STATISTICS:"
  	    ]

    	  ['length', 'keys'].each do |attr|
    	    tab_stops = " " * (20 - attr.length)
    	    lines << "#{tab_stops}#{attr}: #{send(attr).inspect}"
  	    end

        lines << "\nCOMMANDS STATISTICS:"
        command_set.statistics.each do |statistic, value|
    	    tab_stops = " " * (20 - statistic.length)
    	    lines << "#{tab_stops}#{statistic}: #{value.inspect}"
        end

        Snowflake.logger.debug lines.join("\n")
  	    true
  	  end

    	private

    	def command_set
    	  @command_set ||= @operand.eval(nil, true)
  	  end

    	def keys_loaded?
    	  @keys != nil
  	  end

      def elements_loaded?
        @all != nil
      end

      # def keys
      #   @keys ||= ( @operand.eval(nil, true).execute( @operand.results_size ) || [] )
      # end
    end
  end # module Queries
end # module Snowflake