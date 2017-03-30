# https://github.com/vicvega/hpfeeds-ruby/pull/5
module HPFeeds
  class Client
    def initialize(options)
      @host   = options[:host]
      @port   = options[:port] || 10000
      @ident  = options[:ident]
      @secret = options[:secret]

      @timeout   = options[:timeout]   || 30
      @reconnect = options.fetch(:reconnect, true)
      @sleepwait = options[:sleepwait] || 20

      @connected = false
      @stopped   = false

      log_to    = options[:log_to] || STDOUT
      log_level = options[:log_level] || :info
      @logger   = Logger.new(log_to)
      @logger.level = get_log_level(log_level)

      @decoder = Decoder.new
      @handlers   = {}
      @subscribed = []

      tryconnect
    end

    def tryconnect
      loop do
        begin
          connect()
          for c in @subscribed
            subscribe_to_channel c
          end
          break
        rescue => e
          @logger.warn("#{e.class} caught while connecting: #{e}. Reconnecting in #{@sleepwait} seconds...")
          raise(e) unless @reconnect
          sleep(@sleepwait)
        end
      end
    end

    def connect
      @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
      begin
        @logger.debug("connecting #{@host}:#{@port}")
        sockaddr = Socket.pack_sockaddr_in( @port, @host )
        @socket.connect(sockaddr)
      rescue => e
        raise Exception.new("Could not connect to broker: #{e}.")
      end
      @logger.debug("waiting for data")
      header = receive_data(HEADERSIZE, @timeout)
      opcode, len = @decoder.parse_header(header)
      @logger.debug("received header, opcode = #{opcode}, len = #{len}")

      if opcode == OP_INFO
        data = receive_data(len-HEADERSIZE, @timeout)
        @logger.debug("received data = #{binary_to_hex(data)}")
        name, rand = @decoder.parse_info(data)
        @logger.debug("received INFO, name = #{name}, rand = #{binary_to_hex(rand)}")
        @brokername = name
        auth = @decoder.msg_auth(rand, @ident, @secret)
        @socket.send(auth, 0)
      else
        raise Exception.new('Expected info message at this point.')
      end
      @logger.info("connected to #{@host}, port #{@port}")
      @connected = true
      # set keepalive
      @socket.setsockopt(Socket::Option.bool(:INET, :SOCKET, :KEEPALIVE, true))
    end

    def subscribe(*channels, &block)
      if block_given?
        handler = block
      else
        raise ArgumentError.new('When subscribing to a channel, you have to provide a block as a callback for message handling')
      end
      for c in channels
        subscribe_to_channel c
        @handlers[c] = handler unless handler.nil?
        @subscribed << c
      end
    end

    def publish(data, *channels)
      for c in channels
        publish_to_channel c, data
      end
    end

    def stop
      @stopped = true
    end

    def close
      begin
        @logger.debug("Closing socket")
        @socket.close
      rescue => e
        @logger.warn("Socket exception when closing: #{e}")
      end
    end

    def run(error_callback = nil)
      begin
        while !@stopped
          while @connected
            header = receive_data(HEADERSIZE, @timeout)
            if header.empty?
              @connected = false
              break
            end
            opcode, len = @decoder.parse_header(header)
            @logger.debug("received header, opcode = #{opcode}, len = #{len}")
            data = receive_data(len - HEADERSIZE, @timeout)
            if opcode == OP_ERROR
              unless error_callback.nil?
                error_callback.call(data)
              else
                raise ErrorMessage.new(data)
              end
            elsif opcode == OP_PUBLISH
              name, chan, payload = @decoder.parse_publish(data)
              @logger.debug("received #{payload.length} bytes of data from #{name} on channel #{chan}")
              handler = @handlers[chan]
              unless handler.nil?
                # ignore unhandled messages
                handler.call(name, chan, payload)
              end
            end
          end
          @logger.debug("Lost connection, trying to connect again...")
          tryconnect
        end
      rescue Timeout => e
        @logger.warn("#{e.class} caught while connecting: #{e}. Reconnecting in #{@sleepwait} seconds...")
        raise(e) unless @reconnect
        sleep(@sleepwait)
        tryconnect
      rescue ErrorMessage => e
        @logger.warn("#{e.class} caught in main loop: #{e}")
        raise e
      rescue => e
        message = "#{e.class} caught in main loop: #{e}\n"
        message += e.backtrace.join("\n")
        @logger.error(message)
      end
    end

  private
    def binary_to_hex s
      "0x#{s.unpack('H*')[0]}" rescue ''
    end

    def subscribe_to_channel c
      @logger.info("subscribing to #{c}")
      message = @decoder.msg_subscribe(@ident, c)
      @socket.send(message, 0)
    end

    def publish_to_channel c, data
      @logger.info("publish to #{c}: #{data}")
      message = @decoder.msg_publish(@ident, c, data)
      @socket.send(message, 0)
    end

    def receive_data(max, timeout=nil)
      if IO.select([@socket], nil, nil, timeout)
        read_from_socket(max)
      else
        raise Timeout.new("Connection receive timeout.")
      end
    end

    def read_from_socket(max)
      data = ''
      while (data.size < max) do
        data += @socket.recv(max - data.size)
      end
      data
    end

    def get_log_level(level)
      begin
        Logger.const_get(level.to_s.upcase)
      rescue
        raise ArgumentError.new("Unknown log level #{level}")
      end
    end

  end
end
