module StickyElephant
  class Server
    def initialize(configuration)
      @configuration = configuration

      @logger = ElephantLogger.new(configuration)
      @logger.info(log_name) { "Launching" }
    end

    def listen
      server = TCPServer.open(configuration.host, configuration.port)
      Thread.abort_on_exception = configuration.abort_on_exception
      loop do
        begin
          Thread.start(server.accept) do |socket|
            remote_address = begin
                               socket.remote_address.ip_address.to_s
                             rescue Errno::EINVAL
                               "localhost"
                             end
            logger.info(log_name) { "connection from #{remote_address} accepted" }
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

    attr_reader :configuration, :logger

    def log_name
      "SE server"
    end
  end
end
