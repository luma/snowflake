module Snowflake
  module Queries
    module Operations
      class OrOperation < Operation
        protected

      	def command
      		format_command_with_key( :sunionstore, *@operands.collect {|operand| operand.to_key } )
      	end

      	def command_and_return_result
      		format_command( :sunion, *@operands.collect {|operand| operand.to_key } )
      	end
      end
    end # module Operations
  end # module Queries
end # module Snowflake