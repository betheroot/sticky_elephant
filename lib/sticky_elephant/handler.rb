module StickyElephant
  module Handler
    TYPES_HANDLERS = {
      quit:        StickyElephant::Handler::Quit,
      ssl_request: StickyElephant::Handler::SSLRequest,
      query:       StickyElephant::Handler::Query,
      handshake:   StickyElephant::Handler::Handshake,
      invalid:     StickyElephant::Handler::Error,
    }
    def self.for(payload, socket: , logger: )
      klass = TYPES_HANDLERS[payload.type]
      raise StandardError.new("Invalid type #{payload.type} for #{payload}") if klass.nil?
      klass.new(payload, socket: socket, logger: logger)
    end
  end
end
