module Snowflake
  module Queries
    module Operations
      class RandomOperation < Operation
        protected

      	def command_and_return_result
      		format_command( :srandmember, @operands.first.to_key )
      	end
      end
    end # module Operations
  end # module Queries
end # module Snowflake
