module StickyElephant::Errors ; end
class StickyElephant::Errors::InvalidHandshake < StandardError ; end

module StickyElephant
  class Connection
    class SSLRequest < Base
      def self.validates?(payload)
        payload.bytes == [0, 0, 0, 8, 4, 210, 22, 47]
      end

      def process
        log(msg: "Denying SSL request", level: :debug)
        socket.write([0x4e].pack("C"))
      end
    end
  end
end
