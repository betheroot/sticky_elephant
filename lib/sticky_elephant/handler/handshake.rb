module StickyElephant
  module Handler
    class Handshake < Base
      def self.validates?(payload)
        return false if payload.size < 8
        len = payload[0..3].pack('C*').unpack('N').first
        payload.size == len
      end

      def process
        log(msg: 'shaking hands', level: :debug)
        hash = connection_hash.merge(payload_hash)
        password = begin
                     negotiate_auth
                   rescue
                     report_connection(hash)
                     log(level: :error, msg: "#{e}")
                     'NONE PROVIDED'
                   end
        report_connection(hash.merge(password: password))

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
        write_key_data
        response_string = [0x4b, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x01, 0x56,
                           0x7b, 0x27, 0x50, 0xb7, 0x0c, 0x5a, 0x00, 0x00,
                           0x00, 0x05, 0x49].map(&:chr).join
        socket.write(response_string)
      end

      def payload_hash
        payload_arr = payload.raw.pack('C*')[8..-1].split("\x00")
        Hash[*payload_arr.flatten(1)].map {|pair| [pair.first.to_sym, pair.last] }.to_h
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
        password = password_response.bytes[5..-2].map(&:chr).join
        log(msg: "Password: " + password, level: :info)
        socket.write("R")
        socket.write(with_length_bytes("\x00\x00\x00\x00"))
        password
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

      def pid
        666
      end

      def key
        0xEFBEADDE
      end

      def write_parameter_status(key, value)
        to_write = "S" + with_length_bytes("#{key}\x00#{value}\x00")
        socket.write(to_write)
      end
    end
  end
end
