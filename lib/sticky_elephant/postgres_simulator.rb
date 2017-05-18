module StickyElephant
  class PostgresSimulator
    include PostgresProtocol

    attr_reader :response, :query

    def initialize(query_string)
      @query = normalize(query_string)
      simulate
    end

    def to_s
      response
    end

    private

    def simulate
      @response = if version_query?
                    version_response
                  elsif conf_file_query?
                    conf_file_response
                  elsif set_query?
                    set_response
                  else
                    generic_response
                  end
    end

    def generic_response
      %w(54 00 00 00 9c 00 06 69 64 00 00 00 82 1a 00 01 00 00 00 17 00 04 ff ff ff ff 00
        00 6e 61 6d 65 00 00 00 82 1a 00 02 00 00 04 13 ff ff ff ff ff ff 00 00 62 72 65 65 64 00 00 00 82
        1a 00 03 00 00 04 13 ff ff ff ff ff ff 00 00 6e 6f 74 65 73 00 00 00 82 1a 00 04 00 00 04 13 ff ff
        ff ff ff ff 00 00 63 72 65 61 74 65 64 5f 61 74 00 00 00 82 1a 00 05 00 00 04 5a 00 08 ff ff ff ff
        00 00 75 70 64 61 74 65 64 5f 61 74 00 00 00 82 1a 00 06 00 00 04 5a 00 08 ff ff ff ff 00 00 44 00
        00 00 6c 00 06 00 00 00 01 31 00 00 00 04 50 65 72 6c 00 00 00 09 64 72 6f 6d 65 64 61 72 79 00 00
        00 0c 45 6e 6a 6f 79 73 20 72 65 67 65 78 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33
        30 3a 31 30 2e 37 30 39 38 33 35 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31
        30 2e 37 30 39 38 33 35 44 00 00 00 70 00 06 00 00 00 01 32 00 00 00 03 4a 6f 65 00 00 00 09 64 72
        6f 6d 65 64 61 72 79 00 00 00 11 50 61 72 74 69 63 75 6c 61 72 6c 79 20 63 6f 6f 6c 00 00 00 1a 32
        30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 32 33 37 33 00 00 00 1a 32 30 31 36
        2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31 32 33 37 33 44 00 00 00 71 00 06 00 00 00 01
        33 00 00 00 07 41 6c 70 68 6f 6e 73 00 00 00 08 62 61 63 74 72 69 61 6e 00 00 00 0f 48 61 73 20 70
        72 65 74 74 79 20 65 79 65 73 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30
        2e 37 31 34 34 35 37 00 00 00 1a 32 30 31 36 2d 31 32 2d 32 34 20 30 35 3a 33 30 3a 31 30 2e 37 31
        34 34 35 37 43 00 00 00 0d 53 45 4c 45 43 54 20 33 00 5a 00 00 00 05 49).map(&:hex).pack("C*")
    end

    def normalize(s)
      s.downcase
    end

    def version_query?
      query.include? 'select version()'
    end

    def conf_file_query?
      query.include? "select current_setting('config_file')"
    end

    def set_query?
      !!(query =~ /\Aset/)
    end

    def version_response
      version = 'PostgreSQL 9.5.5 on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 4.8.2-19ubuntu1) 4.8.2, 64-bit'
      row_description('version') +
        data_row(version) +
        command_complete(:select, 1) +
        ready_for_query(:idle)
    end

    def conf_file_response
      conf_file = '/etc/postgresql/9.5/main/postgresql.conf'
      row_description('current_setting') +
        data_row(conf_file) +
        command_complete(:select, 1) +
        ready_for_query(:idle)
    end

    def set_response
      parameter, val = parameter_and_value_from_set_query
      parameter_status(parameter, val) +
        command_complete(:set) +
        ready_for_query(:idle)
    end

    SET_QUERY_REGEX = /\Aset\s+(?<restriction>session|local)?\s*(?<parameter>.*?)\s*(?<set_method>to|=)\s*(?<value>.*)\z/
    def parameter_and_value_from_set_query
      match = query.gsub("\n","").match SET_QUERY_REGEX
      [match["parameter"], match["value"].gsub("'", "")]
    end
  end
end
