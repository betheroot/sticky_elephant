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

      def write_key_data
        socket.write("K")
        socket.write(
          with_length_bytes(
            [pid].pack('N') +
            [key].pack('N')
          )
        )
      end

      def write_parameter_status(key, value)
        to_write = "S" + with_length_bytes("#{key}\x00#{value}\x00")
        socket.write(to_write)
        log(msg: "Wrote kv #{to_write}", level: :debug)
      end

      def with_length_bytes(val)
        length = 4 + val.bytesize
        [length].pack("N") + val.to_s
      end

    end
  end
end
