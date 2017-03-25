module StickyElephant::Errors ; end
class StickyElephant::Errors::InvalidHandshake < StandardError ; end

module StickyElephant
  class Connection
    class Handshake < Base
      def process
        log(msg: 'shaking hands', level: :debug)
        log(msg: str, level: :debug)
        hash = parse_handshake_payload(str)
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

      def parse_handshake_payload(packet)
        log(msg: "in read_handshake_payload", level: :debug)

        log(msg: "inital str #{packet}", level: :debug)
        str = packet[8..-1]
        payload_arr = str.split("\x00")
        payload = Hash[*payload_arr.flatten(1)].map {|pair| [pair.first.to_sym, pair.last] }.to_h
        log(msg: "payload #{payload.inspect}", level: :debug)
        payload
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
    end
  end
end
