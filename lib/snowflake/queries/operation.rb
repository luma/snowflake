class Operation
	def initialize( *operands )
		@operands = operands
	end

	def command
		raise NotImplemented
	end

	def to_key
	  @key ||= ::UUIDTools::UUID.random_create.to_s
	end

	def eval(command_set)
		# @todo get child commands
		@operands.each do |operand|
			if operand.is_a?(Operation)
				command_set.concat(operand.command)
			end
		end

		command_set.tmp_keys << tmp_key		
		command_set << command
	end

	private

	def format_command(command, *parameters)
		parameters.unshift( to_key ).unshift( command )
	end
end