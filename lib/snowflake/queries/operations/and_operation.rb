class AndOperation < Operation
	def command
		format_command( :sunionstore, @operands.collect {|operand| operand.to_key } )
	end
end