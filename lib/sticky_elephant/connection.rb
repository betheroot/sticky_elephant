module StickyElephant
  class Connection
    include ::StickyElephant::ElephantLogger

    def initialize(socket, logger: )
      @socket = socket
      @logger = logger
      ip = begin
             socket.remote_address.ip_address
           rescue Errno::EINVAL
             'localhost'
           end
      @logger.info("SE Server") { "connection from #{ip} accepted" }
    end

    def process
      begin
        loop do
          payload = socket.readpartial(1024**2)
          log(msg: "Got #{payload.inspect}", level: :debug)
          obj = Handler.for(payload, socket: socket, logger: logger)
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

  end
end
