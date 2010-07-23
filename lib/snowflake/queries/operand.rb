class Operand
	def initialize(key = nil)
	  @key = key
	end

	def to_key
	  @key ||= ::UUIDTools::UUID.random_create.to_s
	end

	def eval(command_set)
		command_set << format_command( :smembers, to_key )
	end

	private

	def format_command(command, *parameters)
		parameters.unshift( tmp_key ).unshift( command )
	end
end