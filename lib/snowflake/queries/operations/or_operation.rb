module Snowflake
  module Queries
    module Operations
      class OrOperation < Operation
        protected

      	def command
      		format_command( :sunionstore, *@operands.collect {|operand| operand.to_key } )
      	end
      end
    end # module Operations
  end # module Queries
end # module Snowflake