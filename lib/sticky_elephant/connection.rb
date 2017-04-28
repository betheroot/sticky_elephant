module StickyElephant
  class Connection
    include ::StickyElephant::LogInterface

    def initialize(socket, logger: )
      @socket = socket
      @logger = logger
    end

    def process
      begin
        loop do
          @payload = socket.readpartial(1024**2).bytes
          log(msg: "Got #{payload_string}", level: :debug)
          obj = Handler.for(payload, socket: socket, logger: logger)
          log(msg: "Handling with #{obj.class}", level: :debug)
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

    attr_reader :socket, :logger, :payload

  end
end
