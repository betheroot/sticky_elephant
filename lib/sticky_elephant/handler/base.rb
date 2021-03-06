module StickyElephant
  module Handler
    class Base
      include ::StickyElephant::LogInterface

      def initialize(payload, socket: , logger: )
        @payload = payload
        @socket = socket
        @logger = logger
      end

      private

      attr_reader :payload, :socket, :logger

      def with_length_bytes(val)
        length = 4 + val.bytesize
        [length].pack("N") + val.to_s
      end
    end
  end
end
