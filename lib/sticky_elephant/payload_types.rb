module StickyElephant
  module PayloadTypes
    # Order matters
    HANDLER_TYPES = %i(quit ssl_request handshake query invalid).freeze

    def type
      @type ||= HANDLER_TYPES.fetch(handler)
    end

    def handler
      return @handler if defined? @handler
      _handler = HANDLER_TYPES.find {|sym| send("is_#{sym}?") }
      raise RuntimeError.new("Unable to find handler for #{self}") if _handler.nil?
      @handler = _handler
    end

    private

    def is_ssl_request?
      bytes == [0, 0, 0, 8, 4, 210, 22, 47]
    end

    def is_query?
      bytes.first == "Q".ord && valid_length?
    end

    def is_quit?
      bytes.first == "X".ord && valid_length?
    end

    def is_handshake?
      valid_length?
    end

    def is_invalid?
      true
    end

  end
end
