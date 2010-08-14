module Snowflake
  module Queries
    class Operation
    	def initialize( *operands )
    		@operands = operands
    	end
    	
    	def results_size
    	  @results_size ||= 1
  	  end

    	def to_key
    	  @key ||= ::UUIDTools::UUID.random_create.to_s
    	end

    	def eval(cs = nil, top_level = false)
    	  commands = cs != nil ? cs.dup : CommandSet.new

    		# @todo get child commands
    		@operands.each do |operand|
    			if operand.is_a?(Operation)
    				commands.concat( operand.eval(commands) )
    			end
    		end

        # For complex queries the each statement puts its result back into Redis and 
        # indicates which key it used. If this operation will be accumulating a result
        # then that key will need to be added into the list of used keys
        #if accumulate_result?
        if top_level == false
      		commands.keys << to_key		
      		commands << command
    		else
    		  commands << command_and_return_result
    		end

    		commands
    	end

    	# For debugging purposes, think the EXPLAIN statement in SQL
    	def explain(level = 0)
    	  lines = [
    	    ["\t"*level, "#{ActiveSupport::Inflector.demodulize(self.class.to_s)}"].join('')
  	    ]

    	  @operands.each do |operand|
    	    lines << operand.explain(level + 1)
  	    end
  	    
  	    lines.join("\n")
  	  end

    	protected

    	def command
    		raise NotImplementedError
    	end

    	def command_and_return_result
    		raise NotImplementedError
    	end

    	def format_command(command, *parameters)
    		parameters.unshift( command )
    	end

    	def format_command_with_key(command, *parameters)
    		parameters.unshift( to_key ).unshift( command )
    	end
    end
  end # module Queries
end # module Snowflake