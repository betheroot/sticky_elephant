module StickyElephant
  module Handler
    def self.for(payload, socket: , logger: )
      case payload[0]
      when "\x00"
        if SSLRequest.validates?(payload)
          SSLRequest.new(payload, socket: socket, logger: logger)
        elsif Handshake.validates?(payload)
          Handshake.new(payload, socket: socket, logger: logger)
        else
          Error.new(payload, socket: socket, logger: logger)
        end
      when 'Q'
        Query.new(payload, socket: socket, logger: logger)
      when 'X'
        Null.new(payload, socket: socket, logger: logger)
      else
        logger.send(:debug, socket.remote_address.ip_address) { "Unknown input: #{payload}" }
        Null.new(payload, socket: socket, logger: logger)
      end
    end
  end
end