require 'socket'
require 'pry-byebug'
require 'optparse'
require 'logger'

class StickyElephantCLI
  def opts_from_cli
    options = {}
    opt_parser = OptionParser.new do |opts|
      opts.program_name = File.basename(__FILE__)
      opts.banner = "#{opts.program_name} [options]"
      opts.on('-p PORT', '--port PORT', 'Port to bind') { |port| options[:port] = port.to_i }
      opts.on('-a ADDRESS', '--address ADDRESS', 'Host address to bind') { |addr| options[:host] = addr }
      opts.on("-d", "--debug", "Debug information") { options[:loglevel] = Logger::DEBUG }
      opts.on('-h', '--help', 'Display this screen') { puts opts ; exit(0) }
    end
    begin
      opt_parser.parse!
    rescue OptionParser::InvalidOption => e
      puts e.message
      exit false
    end
    options
  end

  def run
    options = opts_from_cli do |h|
      h[:loglevel] = Logger::INFO unless h.has_key?(:logelevel)
    end
    StickyElephant.new(options).listen
  end
end

class StickyElephant
  attr_reader :host, :port, :server, :logger
  def initialize(host: '0.0.0.0', port: 5432, loglevel: Logger::INFO)
    @host = host
    @port = port

    @logger = Logger.new("sticky_elephant.log")
    @logger.level = loglevel
    @logger.progname = "Sticky Elephant client"
    @logger.info("Sticky Elephant server") { "Launching" }
  end

  def listen
    @server = TCPServer.open(host, port)
    loop do
      begin
        Thread.start(server.accept) do |cli|
          client = StickyElephantClient.new(cli, logger: logger)
          puts("connection from #{client} accepted")
          client.process
        end
      rescue Interrupt
        log(msg: "Caught ctrl-c, shutting down", level: :info)
        Thread.list.each {|t| t.kill unless t == Thread.current }
        logger.close
        exit(0)
      end
    end
  end
end

class StickyElephantClient
  attr_reader :socket, :logger
  def initialize(socket, logger: )
    @socket = socket
    @logger = logger
  end

  def process
    begin
      loop do
        str = socket.readpartial(1024**2)
        log(msg: "Got #{str.inspect}", level: :debug)
        case str[0]
        when "\x00"
          if str.bytes == [0, 0, 0, 8, 4, 210, 22, 47]
            log(msg: "Trying SSL", level: :debug)
            socket.write([0x4e].pack("C"))
          else
            handshake(str)
          end
        when 'Q'
          parse_query(str[1..-1])
        when 'X'
          break
        else
          handshake(str)
        end
      end
    rescue => e
      log(msg: e, level: :error)
    ensure
      socket.close
      Thread.exit
    end
  end

  private

  def parse_handshake_payload(packet)
    log(msg: "in read_handshake_payload", level: :debug)

    str = packet[8..-1]
    payload_arr = str.split("\x00")
    payload = Hash[*payload_arr.flatten(1)].map {|pair| [pair.first.to_sym, pair.last] }.to_h
    log(msg: "payload #{payload.inspect}", level: :debug)
    payload
  end

  def write_parameter_status(key, value)
    @n ||= 1
    to_write = "S" + with_length_bytes("#{key}\x00#{value}\x00")
    socket.write(to_write)
    log(msg: "Wrote kv ##{@n}: #{to_write}", level: :debug)
    @n += 1
  end

  def with_length_bytes(val)
    length = 4 + val.bytesize
    [length].pack("N") + val.to_s
  end

  def negotiate_auth
    socket.write("R")
    socket.write(with_length_bytes("\x00\x00\x00\x03"))
    IO.select([socket], nil, nil, 60)
    begin
      password_response = socket.readpartial(1024)
    rescue EOFError
      sleep 0.01
      retry
    end
    log(msg: "Password: " + password_response.bytes[5..-2].map(&:chr).join, level: :info)
    socket.write("R")
    socket.write(with_length_bytes("\x00\x00\x00\x00"))
  end

  def pid
    666
  end

  def key
    0xEFBEADDE
  end

  def write_key_data
    socket.write("K")
    socket.write(
      with_length_bytes(
        [pid].pack('N') +
        [key].pack('N')
      )
    )
  end

  def handshake(packet)
    log(msg: 'shaking hands', level: :debug)
    log(msg: packet, level: :debug)
    hash = parse_handshake_payload(packet)
    negotiate_auth
    write_parameter_status("application_name", hash[:application_name])
    write_parameter_status("client_encoding", hash[:client_encoding])
    write_parameter_status("DateStyle", "ISO, MDY")
    write_parameter_status("integer_datetimes", "on")
    write_parameter_status("IntervalStyle", "postgres")
    write_parameter_status("is_superuser", "on")
    write_parameter_status("server_encoding", hash[:client_encoding])
    write_parameter_status("server_version", "9.5.5")
    write_parameter_status("session_authorization", hash[:user])
    write_parameter_status("standard_conforming_strings", "on")
    write_parameter_status("TimeZone", "US/Pacific")
    response_string = [0x4b, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x01, 0x56,
                        0x7b, 0x27, 0x50, 0xb7, 0x0c, 0x5a, 0x00, 0x00,
                        0x00, 0x05, 0x49].map(&:chr).join
    socket.write(response_string)
  end

  def response
    @response ||= %w(54 00 00 00 9c 00 06 69 64 00 00 00 82 1a 00 01 00 00 00 17 00 04 ff ff ff ff 00 00 6e 61 6d 65 00 00 00 82 1a 00 02 00 00 04 13 ff ff ff ff ff ff 00 00 62 72 65 65 64 00 00 00 82 1a 00 03 00 00 04 13 ff ff ff ff ff ff 00 00 6e 6f 74 65 73 00 00 00 82 1a 00 04 00 00 04 13 ff ff ff ff ff ff 00 00 63 72 65 61 74 65 64 5f 61 74 00 00 00 82 1a 00 05 00 00 04 5a 00 08 ff ff ff ff 00 00 75 70 64 61 74 65 64 5f 61 74 00 00 00 82 1a 00 06 00 00 04 5a 00 08 ff ff ff ff 00 00 44 00 00 00 6c 00 06 00 00 00 01 31 00 00 00 04 50 65 72 6c 00 00 00 09 64 72 6f 6d 65 64 61 72 79 00 00 00 0c 45 6e 6a 6f 79 73 20 72 65 67 65 78 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 30 39 38 33 35 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 30 39 38 33 35 44 00 00 00 70 00 06 00 00 00 01 32 00 00 00 03 4a 6f 65 00 00 00 09 64 72 6f 6d 65 64 61 72 79 00 00 00 11 50 61 72 74 69 63 75 6c 61 72 6c 79 20 63 6f 6f 6c 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 32 33 37 33 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 32 33 37 33 44 00 00 00 71 00 06 00 00 00 01 33 00 00 00 07 41 6c 70 68 6f 6e 73 00 00 00 08 62 61 63 74 72 69 61 6e 00 00 00 0f 48 61 73 20 70 72 65 74 74 79 20 65 79 65 73 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 34 34 35 37 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 34 34 35 37 43 00 00 00 0d 53 45 4c 45 43 54 20 33 00 5a 00 00 00 05 49).map(&:hex).map(&:chr).join
  end

  def log(msg: , level: )
    logger.send(level, msg)
  end

  def parse_query(query)
    log(msg: query, level: :debug)
    log(msg: "QUERY: #{query}", level: :info)
    socket.write(response)
  end
end
StickyElephantCLI.new.run
