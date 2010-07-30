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

    	def execute
    		results = Snowflake.connection.multi do |multi|
    			# Execute the commands
    			each do |command|
    				multi.send( *command )
    			end

          unless keys.empty?
      			# Get the result
      			multi.smembers( keys.last )

      			# Delete the temp keys
      			keys.each do |key|
      				multi.del( key )
      			end
    			end
    		end

    		# @todo check for errors

    		# return the result
    		results[ keys.empty?? length - 1 : length ]	  
      end
    end
  end # module Queries
end # module Snowflake