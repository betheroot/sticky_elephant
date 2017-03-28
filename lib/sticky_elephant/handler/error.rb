module StickyElephant
  module Handler
    class Error < Base
      def process
        socket.write(error_payload)
      end

      private

      def error_payload
        %w(
        45 00 00 00 84 53 46 41 54 41 4c 00 43 30 41 30
        30 30 00 4d 75 6e 73 75 70 70 6f 72 74 65 64 20
        66 72 6f 6e 74 65 6e 64 20 70 72 6f 74 6f 63 6f
        6c 20 36 35 33 36 33 2e 31 39 37 37 38 3a 20 73
        65 72 76 65 72 20 73 75 70 70 6f 72 74 73 20 31
        2e 30 20 74 6f 20 33 2e 30 00 46 70 6f 73 74 6d
        61 73 74 65 72 2e 63 00 4c 32 30 30 35 00 52 50
        72 6f 63 65 73 73 53 74 61 72 74 75 70 50 61 63
        6b 65 74 00 00).map(&:hex).map(&:chr).join
      end
    end
  end
end
