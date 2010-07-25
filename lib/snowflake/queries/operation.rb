module Snowflake
  module Queries
    class Operation
    	def initialize( *operands )
    		@operands = operands
    	end

    	def to_key
    	  @key ||= ::UUIDTools::UUID.random_create.to_s
    	end

    	def eval(cs = nil)
    	  commands = cs != nil ? cs.dup : CommandSet.new

    		# @todo get child commands
    		@operands.each do |operand|
    			if operand.is_a?(Operation)
    				commands.concat( operand.eval(commands) )
    			end
    		end

    		commands.keys << to_key		
    		commands << command
    		commands
    	end

    	protected

    	def command
    		raise NotImplemented
    	end

    	def format_command(command, *parameters)
    		parameters.unshift( to_key ).unshift( command )
    	end
    end
  end # module Queries
end # module Snowflake