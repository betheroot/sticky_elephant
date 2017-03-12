require 'socket'
require 'pry-byebug'

class StickyElephant
  attr_reader :host, :port, :server
  def initialize(host: '0.0.0.0', port: 5432)
    @host = host
    @port = port
  end

  def listen
    @server = TCPServer.open(host, port)
    loop do
      Thread.start(server.accept) do |cli|
        client = StickyElephantClient.new(cli)
        puts("connection from #{client} accepted")
        client.process
      end
    end
  end
end

class StickyElephantClient
  attr_reader :socket
  def initialize(socket)
    @socket = socket
  end

  def process
    begin
      loop do
        puts "top of loop" if debug?
        str = socket.readpartial(1024**2)
        puts "Got #{str.inspect}" if debug?
        case str[0]
        when "\x00"
          if str.bytes == [0, 0, 0, 8, 4, 210, 22, 47]
            puts "Trying SSL" if debug?
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
      puts e if debug?
      raise e if debug?
      log("ERROR: #{e}")
    ensure
      socket.close
      Thread.exit
    end
  end

  private

  def debug?
    false
  end

  def read_int
    puts 'in read_int' if debug?
    res = ''
    begin
      res = socket.recv(4)
    rescue => e
      puts "Error"
      puts "#{e}"
    end
    puts res.bytes.map {|b| "0x#{ b.ord.to_s(16)}" }.join(" ") if debug?
    ret = res.unpack('N').first
    puts ret if debug?
    ret
  end

=begin
  def read_str
    keep_reading = true
    bytes = []
    until !keep_reading
      readable, _writable, _error = IO.select([socket], [socket], nil, 3)
      if readable == [socket]
        byte = socket.recv(1)
        break if byte == ''
        # puts "got byte 0x#{byte.ord.to_s(16)}" if debug?
        print byte
        bytes << byte
      else
        keep_reading = false
      end
    end
    bytes.join
  end
=end

  def parse_handshake_payload(packet)
    puts "in read_handshake_payload" if debug?

    str = packet[8..-1]
    payload_arr = str.split("\x00")
    payload = Hash[*payload_arr.flatten(1)].map {|pair| [pair.first.to_sym, pair.last] }.to_h
    puts "payload #{payload.inspect}" if debug?
    payload
  end

  def write_parameter_status(key, value)
    @n ||= 1
    to_write = "S" + with_length_bytes("#{key}\x00#{value}\x00")
    socket.write(to_write)
    puts "Wrote kv ##{@n}: #{to_write}" if debug?
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
    password_response = socket.readpartial(1024)
    log("Password: " + password_response.bytes[5..-2].map(&:chr).join)
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
    log(packet)
    puts 'shaking hands' if debug?
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
    write_parameter_status("#session_authorization", hash[:user])
    write_parameter_status("#standard_conforming_strings", "on")
    write_parameter_status("TimeZone", "US/Pacific")
    response_string = [0x4b, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x01, 0x56,
                        0x7b, 0x27, 0x50, 0xb7, 0x0c, 0x5a, 0x00, 0x00,
                        0x00, 0x05, 0x49].map(&:chr).join
    socket.write(response_string)
  end

  def response
    @response ||= %w(54 00 00 00 9c 00 06 69 64 00 00 00 82 1a 00 01 00 00 00 17 00 04 ff ff ff ff 00 00 6e 61 6d 65 00 00 00 82 1a 00 02 00 00 04 13 ff ff ff ff ff ff 00 00 62 72 65 65 64 00 00 00 82 1a 00 03 00 00 04 13 ff ff ff ff ff ff 00 00 6e 6f 74 65 73 00 00 00 82 1a 00 04 00 00 04 13 ff ff ff ff ff ff 00 00 63 72 65 61 74 65 64 5f 61 74 00 00 00 82 1a 00 05 00 00 04 5a 00 08 ff ff ff ff 00 00 75 70 64 61 74 65 64 5f 61 74 00 00 00 82 1a 00 06 00 00 04 5a 00 08 ff ff ff ff 00 00 44 00 00 00 6c 00 06 00 00 00 01 31 00 00 00 04 50 65 72 6c 00 00 00 09 64 72 6f 6d 65 64 61 72 79 00 00 00 0c 45 6e 6a 6f 79 73 20 72 65 67 65 78 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 30 39 38 33 35 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 30 39 38 33 35 44 00 00 00 70 00 06 00 00 00 01 32 00 00 00 03 4a 6f 65 00 00 00 09 64 72 6f 6d 65 64 61 72 79 00 00 00 11 50 61 72 74 69 63 75 6c 61 72 6c 79 20 63 6f 6f 6c 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 32 33 37 33 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 32 33 37 33 44 00 00 00 71 00 06 00 00 00 01 33 00 00 00 07 41 6c 70 68 6f 6e 73 00 00 00 08 62 61 63 74 72 69 61 6e 00 00 00 0f 48 61 73 20 70 72 65 74 74 79 20 65 79 65 73 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 34 34 35 37 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 34 34 35 37 43 00 00 00 0d 53 45 4c 45 43 54 20 33 00 5a 00 00 00 05 49).map(&:hex).map(&:chr).join
  end
  def parse_query(query)
    puts "QUERY: #{query}" if debug?
    log(query)
    socket.write(response)
  end

  def log(item)
    File.open("sticky_elephant.log", 'a') do |f|
      logline = "#{socket.remote_address.inspect} - #{item}"
      f.puts(logline)
    end
  end

end

StickyElephant.new.listen
