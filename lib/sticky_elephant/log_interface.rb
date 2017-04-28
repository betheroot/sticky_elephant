module StickyElephant
  module LogInterface

    private

    def log(level: , msg: )
      logger.send(level, remote_address) { string_from(msg) }
    end

    def report_query(str = payload_string)
      json = JSON.dump(
        connection_hash.merge( { query: string_from(str) } )
      )
      logger.event(:query, json)
    end

    def report_connection(hash = connection_hash)
      logger.event(:connection, JSON.dump(hash))
    end

    def connection_hash
      {
        source_ip: remote_address,
        dest_ip: local_address,
        source_port: remote_port,
        dest_port: local_port,
        raw: payload_string,
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

    def payload_string
      payload.pack("C*")
    end

    def string_from(byte_array)
      if byte_array.is_a? Array
        byte_array.pack("C*")
      else
        byte_array
      end
    end
  end
end
