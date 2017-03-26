module StickyElephant
  class Connection
    class Handshake < Base
      def self.validates?(payload)
        return false if payload.bytesize < 8
        len = payload[0..3].unpack('N').first
        payload.bytesize == len
      end

      def process
        log(msg: 'shaking hands', level: :debug)
        log(msg: payload, level: :debug)
        hash = parse_handshake_payload
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

      def parse_handshake_payload
        log(msg: "in parse_handshake_payload", level: :debug)

        log(msg: "inital str #{payload}", level: :debug)
        payload_arr = payload[8..-1].split("\x00")
        payload_hash = Hash[*payload_arr.flatten(1)].map {|pair| [pair.first.to_sym, pair.last] }.to_h
        log(msg: "payload #{payload_hash.inspect}", level: :debug)
        payload_hash
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
    end
  end
end
