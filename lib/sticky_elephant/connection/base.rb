module StickyElephant
  class Connection
    class Base
      def initialize(payload, socket: , logger: )
        @payload = payload
        @socket = socket
        @logger = logger
      end

      private

      attr_reader :payload, :socket, :logger

      def log(msg: , level: )
        logger.send(level, socket.remote_address.ip_address) { msg }
      end

      def with_length_bytes(val)
        length = 4 + val.bytesize
        [length].pack("N") + val.to_s
      end
    end
  end
end
