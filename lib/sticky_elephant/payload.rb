module StickyElephant
  class Payload
    def self.valid?(bytes)
      Payload.new(bytes).valid?
    end

    def initialize(bytes = [])
      @bytes = bytes.dup.freeze
    end

    VALID_TYPES=%i(ssl_request handshake quit query).freeze
    def valid?
      VALID_TYPES.include? type
    end

    def to_s
      bytes.pack("C*")
    end

    def ==(arr)
      bytes == arr
    end

    # Order matters
    HANDLER_TYPES = {
      StickyElephant::Handler::Quit       => :quit,
      StickyElephant::Handler::SSLRequest => :ssl_request,
      StickyElephant::Handler::Handshake  => :handshake,
      StickyElephant::Handler::Query      => :query,
      StickyElephant::Handler::Error      => :invalid
    }.freeze

    def type
      @type ||= HANDLER_TYPES.fetch(handler)
    end

    def handler
      return @handler if defined? @handler
      _handler = HANDLER_TYPES.keys.find {|const| const.validates?(bytes) }
      raise RuntimeError.new("Unable to find handler for #{self}") if _handler.nil?
      @handler = _handler
    end

    def valid_length?
      if has_claimed_type?
        bytes[1..4].pack("C*").unpack("N") == bytes.size - 1
      else
        bytes[0..3] == bytes.size
      end
    end

    private

    CLAIMED_TYPES=%w(X Q).freeze
    def has_claimed_type?
      CLAIMED_TYPES.include? bytes.first
    end

    attr_reader :bytes
  end
end
