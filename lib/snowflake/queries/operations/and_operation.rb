module Snowflake
  module Queries
    module Operations
      class AndOperation < Operation
        protected

      	def command
      		format_command( :sinterstore, *@operands.collect {|operand| operand.to_key } )
      	end
      end
    end # module Operations
  end # module Queries
end # module Snowflake