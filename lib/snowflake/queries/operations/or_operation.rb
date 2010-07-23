class OrOperation < Operation
	def command
		format_command( :sinterstore, @operands.collect {|operand| operand.to_key } )
	end
end