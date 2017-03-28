module StickyElephant
  module ElephantLogger

    private

    def log(level: , msg: )
      @logger.send(level, socket.remote_address.ip_address) { msg }
    end
  end
end
