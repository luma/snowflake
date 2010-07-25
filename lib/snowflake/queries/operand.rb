module Snowflake
  module Queries
    class Operand
    	def initialize(key = nil)
    	  @key = key
    	end

    	def to_key
    	  @key ||= ::UUIDTools::UUID.random_create.to_s
    	end

    	def eval(cs = nil)
    	  commands = cs != nil ? cs.dup : CommandSet.new
    		commands << format_command( :smembers )
    		commands
    	end

    	private

    	def format_command(command, *parameters)
    		parameters.unshift( to_key ).unshift( command )
    	end
    end
  end # module Queries
end # module Snowflake