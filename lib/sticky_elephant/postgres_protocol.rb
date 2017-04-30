module StickyElephant
  module PostgresProtocol
    READY_FOR_QUERY_STATUSES = { idle: 'I', transaction: 'T', failed: 'E' }.freeze
    def ready_for_query(sym)
      unless READY_FOR_QUERY_STATUSES.include?(sym)
        raise ArgumentError.new("#{sym} not in #{READY_FOR_QUERY_STATUSES}")
      end
      (
        [ 'Z'.ord ] +
        with_length(READY_FOR_QUERY_STATUSES.fetch(sym))
      ).pack('C*')
    end

    COMMAND_COMPLETE_COMMANDS = %i(insert delete update select move fetch copy create).freeze
    def command_complete(sym, num)
      unless COMMAND_COMPLETE_COMMANDS.include?(sym)
        raise ArgumentError.new("#{sym} not in #{COMMAND_COMPLETE_COMMANDS}") 
      end
      sym = :select if sym == :create
      (
       ["C".ord ] +
       with_length("#{sym.to_s.upcase} #{num}\x00")
      ).pack("C*")
    end

    def data_row(*rows)
      results_block = rows.flat_map do |row|
        (int32_bytes(row.length) + row.bytes)
      end

      (
        [ "D".ord ] +
        with_length(
          int16_bytes(rows.count) +
          results_block
        )
      ).pack("C*")
    end

    def row_description(*rows)
      fields_block = rows.map do |row|
        row + "\x00" +    # str   Field name
          ("\x00" * 4) + # int32 If column of specific table, object ID of table;  else zero.
          ("\x00" * 2) + # int16 If column of specific table, attribute# of column; else zero.
          ("\x00\x00\x00\x19") + # int32 Object ID of field's data type
          ("\xFF\xFF") + # int16 Data type size
          ("\xFF\xFF\xFF\xFF") + # int32 Type modifier
          ("\x00\x00")   # int16 Format code: 0 for text, 1 for binary
      end.join.bytes
      num_fields = int16_bytes(rows.count)
      (
        ['T'.ord ] + # byte - message
        with_length(num_fields + fields_block)
      ).pack("C*")
    end

    def with_length(obj)
      bytes = obj.respond_to?(:bytes) ? obj.bytes : obj
      raise ArgumentError.new("Must be an array or respond to #bytes") unless bytes.is_a?(Array)

      length = 4 + bytes.size
      int32_bytes(length) + bytes
    end

    def int32_bytes(num)
      [num].pack("N").unpack("C*")
    end

    def int16_bytes(num)
      [num].pack("n").unpack("C*")
    end
  end
end
