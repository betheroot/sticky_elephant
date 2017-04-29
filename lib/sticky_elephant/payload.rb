module StickyElephant
  class Payload
    include PayloadTypes

    def initialize(bytes = [])
      @bytes = bytes.dup.freeze
    end

    VALID_TYPES=%i(ssl_request handshake quit query).freeze
    def valid?
      VALID_TYPES.include? type
    end

    def ==(arr)
      bytes == arr
    end

    def valid_length?
      if has_claimed_type?
        bytes[1..4].pack("C*").unpack("N").first == bytes.size - 1
      else
        bytes[0..3].pack("C*").unpack("N").first == bytes.size
      end
    end

    def to_s
      message = without_length.
        select {|byte| byte != 0 }.
        pack("C*")
      "#{type.to_s.upcase}: '#{message}'"
    end

    def raw
      bytes
    end

    private

    def without_length
      if has_claimed_type?
        bytes[5..-1]
      else
        bytes[4..-1]
      end
    end

    CLAIMED_TYPES=%w(X Q).freeze
    def has_claimed_type?
      CLAIMED_TYPES.include? bytes.first.chr
    end

    attr_reader :bytes
  end
end
