module StickyElephant
  module Handler
    class Error < Base
      def process
        socket.write(handshake_error)
      end

      private

      def handshake_error
        error_response_for(
          severity: :error,
          code: "0A000",
          message: "unsupported frontend protocol 65363.19778: server supports 1.0 to 3.0",
          file: "postmaster.c",
          line: "2005",
          routine: "ProcessStartupPacket"
        )
      end

      ERROR_RESPONSE_SEVERITY = {
        error: "ERROR",
        fatal: "FATAL",
        panic: "PANIC",
        warning: "WARNING",
        notice: "NOTICE",
        debug: "DEBUG",
        info: "INFO",
        log: "LOG"
      }.freeze

      ERROR_CODES = %w(00000 01000 0100C 01008 01003 01007 01006 01004 01P01 02000 02001 03000 08000 08003
                       08006 08001 08004 08007 08P01 09000 0A000 0B000 0F000 0F001 0L000 0LP01 0P000 0Z000
                       0Z002 20000 21000 22000 2202E 22021 22008 22012 22005 2200B 22022 22015 2201E 22014
                       22016 2201F 2201G 22018 22007 22019 2200D 22025 22P06 22010 22023 2201B 2201W 2201X
                       22009 2200C 2200G 22004 22002 22003 22026 22001 22011 22027 22024 2200F 22P01 22P02
                       22P03 22P04 22P05 2200L 2200M 2200N 2200S 2200T 23000 23001 23502 23503 23505 23514
                       23P01 24000 25000 25001 25002 25008 25003 25004 25005 25006 25007 25P01 25P02 26000
                       27000 28000 28P01 2B000 2BP01 2D000 2F000 2F005 2F002 2F003 2F004 34000 38000 38001
                       38002 38003 38004 39000 39001 39004 39P01 39P02 3B000 3B001 3D000 3F000 40000 40002
                       40001 40003 40P01 42000 42601 42501 42846 42803 42P20 42P19 42830 42602 42622 42939
                       42804 42P18 42P21 42P22 42809 42703 42883 42P01 42P02 42704 42701 42P03 42P04 42723
                       42P05 42P06 42P07 42712 42710 42702 42725 42P08 42P09 42P10 42611 42P11 42P12 42P13
                       42P14 42P15 42P16 42P17 44000 53000 53100 53200 53300 53400 54000 54001 54011 54023
                       55000 55006 55P02 55P03 57000 57014 57P01 57P02 57P03 57P04 58000 58030 58P01 58P02
                       F0000 F0001 HV000 HV005 HV002 HV010 HV021 HV024 HV007 HV008 HV004 HV006 HV091 HV00B
                       HV00C HV00D HV090 HV00A HV009 HV014 HV001 HV00P HV00J HV00K HV00Q HV00R HV00L HV00M
                       HV00N P0000 P0001 P0002 P0003 XX000 XX001 XX002).freeze

      def error_response_for(severity: :error, code: , message: , file: , line:, routine: )
        severity = severity.to_sym
        unless ERROR_RESPONSE_SEVERITY.include? severity
          raise ArgumentError.new("Severity #{severity} not in #{ERROR_RESPONSE_SEVERITY.keys.join(', ')}")
        end

        unless ERROR_CODES.include? code.to_s
          raise ArgumentError.new("Code #{code} not in code list")
        end

        error_payload = [ "S#{ERROR_RESPONSE_SEVERITY.fetch(severity)}",
            "C#{code}",
            "M#{message}",
            "F#{file}",
            "L#{line}",
            "R#{routine}\x00"
        ].map {|s| "#{s}\x00"}.join

        "E" + with_length_bytes(error_payload)
      end
    end
  end
end
