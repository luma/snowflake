module Snowflake
  class Listener
    attr_reader :address, :context, :socket

    # address should be a string like tcp://127.0.0.1
    def initialize(address = "tcp://127.0.0.1:9997")
      @address = address
      @context = ZMQ::Context.new
      @socket = @context.socket(ZMQ::DOWNSTREAM)
      @socket.connect(@address)
    end

    def broadcast(event, key, payload)
      puts "Broadcasting #{event} to #{@address} for \"#{key}\""
      unless self.class.broadcast_disabled?
        @socket.send( {:event => event, :key => key, :payload => payload}.to_json )
      end
    end

    class << self
      def broadcast_disabled?
        @broadcast_disabled ||= false
      end

      def broadcast_disabled=(state)
        @broadcast_disabled = state
      end
    end
  end
end # module Snowflake