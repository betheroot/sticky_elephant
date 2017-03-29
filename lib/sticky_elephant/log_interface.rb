module StickyElephant
  module LogInterface

    private

    def log(level: , msg: )
      logger.send(level, socket.remote_address.ip_address) { msg }
    end

    def report_query
      json = JSON.dump(connection_payload.merge({query: payload}))
      logger.event(:query, json)
    end

    def report_connection
      logger.event(:query, JSON.dump(connection_payload))
    end

    def connection_payload
      {
        source_ip: remote_address,
        dest_ip: local_address,
        source_port: remote_port,
        dest_port: local_port,
      }
    end

    def remote_address
      begin
        socket.remote_address.ip_address.to_s
      rescue Errno::EINVAL
        "localhost"
      end
    end

    def remote_port
      socket.remote_address.ip_port.to_s
    end

    def local_address
      socket.local_address.ip_address.to_s
    end

    def local_port
      socket.local_address.ip_port.to_s
    end
  end
end
