module StickyElephant
  module PayloadTypes
    # Order matters
    TYPES = %i( quit ssl_request query handshake invalid ).freeze

    def type
      return @type if defined? @type
      _type = TYPES.find {|sym| send("is_#{sym}?") }
      raise RuntimeError.new("Unable to find type for #{self}") if _type.nil?
      @type = _type
    end

    def handler
      TYPES_HANDLERS.fetch(type)
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
