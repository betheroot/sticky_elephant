module StickyElephant
  class CLI
    def run
      options = opts_from_cli.tap do |h|
        h[:log_level] = Logger::INFO unless h.has_key?(:log_level)
      end
      Server.new(options).listen
    end

    private

    def opts_from_cli
      options = {}
      opt_parser = OptionParser.new do |opts|
        opts.program_name = "sticky_elephant"
        opts.banner = "#{opts.program_name} [options]"
        opts.on('-p PORT', '--port PORT', 'Port to bind') { |port| options[:port] = port.to_i }
        opts.on('-a ADDRESS', '--address ADDRESS', 'Host address to bind') { |addr| options[:host] = addr }
        opts.on("-d", "--debug", "Debug information") { options[:log_level] = Logger::DEBUG }
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
  end
end
