module StickyElephant
  class Connection
    def initialize(socket, logger: )
      @socket = socket
      @logger = logger
    end

    def self.log *args
      pp(*args)
    end

    def self.for(socket, logger: )
      str = socket.readpartial(1024**2)
      log(msg: "Got #{str.inspect}", level: :debug)
      case str[0]
      when "\x00"
        if SSLRequest.validates?(str)
          SSLRequest.new(str, socket: socket, logger: logger)
        else
          Handshake.new(str, socket: socket, logger: logger)
        end
      when 'Q'
        Query.new(str, socket: socket, logger: logger)
      when 'X'
        nil
      else
        log(msg: "Unknown input #{str}", level: :debug)
        nil
      end
    end

    def process
      begin
        loop do
          obj = Connection.for(socket, logger: logger)
          log(msg: "#{obj.class}", level: :debug)
          obj.process
        end
      rescue => e
        log(msg: e, level: :error) unless e.is_a? EOFError
      ensure
        socket.close
        Thread.exit
      end
    end

    private

    attr_reader :socket, :logger

    def log(msg: , level: )
      logger.send(level, socket.remote_address.ip_address) { msg }
    end

  end
end
