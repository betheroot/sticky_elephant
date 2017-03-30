module StickyElephant
  class Server
    def initialize(host: '0.0.0.0', port: 5432, log_level: Logger::INFO)
      @host = host
      @port = port

      @logger = ElephantLogger.new
      @logger.level = log_level
      @logger.info(log_name) { "Launching" }
    end

    def listen
      @server = TCPServer.open(host, port)
      loop do
        begin
          Thread.start(server.accept) do |socket|
            Connection.new(socket, logger: logger).process
          end
        rescue Interrupt
          logger.info(log_name) { "Caught ctrl-c, shutting down" }
          Thread.list.each {|t| t.kill unless t == Thread.current }
          logger.close
          exit(0)
        end
      end
    end

    private

    attr_reader :host, :port, :server, :logger

    def log_name
      "SE server"
    end
  end
end
