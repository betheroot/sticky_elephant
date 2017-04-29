module StickyElephant
  module Handler
    class SSLRequest < Base
      def process
        log(msg: "Denying SSL request", level: :debug)
        socket.write([0x4e].pack("C"))
      end
    end
  end
end
