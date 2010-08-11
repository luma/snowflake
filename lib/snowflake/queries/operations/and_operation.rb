module Snowflake
  module Queries
    module Operations
      class AndOperation < Operation
        protected

      	def command
      		format_command_with_key( :sinterstore, *@operands.collect {|operand| operand.to_key } )
      	end

      	def command_and_return_result
      		format_command( :sinter, *@operands.collect {|operand| operand.to_key } )
      	end
      end
    end # module Operations
  end # module Queries
end # module Snowflake