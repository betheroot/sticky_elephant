module StickyElephant
  class CLI
    def run
      options = opts_from_cli
      conf_path = options.fetch(:configuration_path, "sticky_elephant.conf")
      config = Configuration.new(conf_path)
      Server.new(config).listen
    end

    private

    def opts_from_cli
      options = {}
      opt_parser = OptionParser.new do |opts|
        opts.program_name = "sticky_elephant"
        opts.banner = "#{opts.program_name} [options]"
        opts.on('-c CONFIG', '--config CONFIG', 'Configuration file to read') do |conf|
          options[:configuration_path] = conf
        end
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
