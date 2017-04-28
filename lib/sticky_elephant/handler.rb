module StickyElephant
  module Handler
    def self.for(payload, socket: , logger: )
      payload.handler.new(payload, socket: socket, logger: logger)
    end
  end
end
