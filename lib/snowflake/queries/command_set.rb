module Snowflake
  module Queries
    class CommandSet < Array
    	def initialize
    		super
    	end

      # any keys that are used for these commands
    	def keys
    		@keys ||= []
    	end
	
    	def clear
    	  super
    	  @tmp_keys == []
      end

    	def execute( results_size = 1)
        if empty?
          return nil
        end

        case length
        when 0
          nil
        when 1
          Snowflake.connection.send( *first )
        else
          execute_multiple( results_size )
        end
      end
      
      private
      
      def execute_multiple( results_size = 1 )
    		results = Snowflake.connection.multi do |multi|
    			# Execute the commands
    			each do |command|
    				multi.send( *command )
    			end

          unless keys.empty?
      			# Delete the temp keys
      			keys.each do |key|
      				multi.del( key )
      			end
    			end
    		end

    		# @todo check for errors

    		# return the result
    		results_start = length - keys.length - results_size
    		results_end = length - keys.length - 1

    		results = results[results_start..results_end]

    		case results.length 
  		  when 0
  		    nil
		    when 1
		      results.first
	      else
	        results
        end
      end
      
    end
  end # module Queries
end # module Snowflake