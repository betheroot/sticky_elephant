module StickyElephant
  class Configuration
    attr_reader :log_path, :log_level, :port, :host, :abort_on_exception,
      :hpf_host, :hpf_port, :hpf_ident, :hpf_secret, :debug
    alias_method :debug?, :debug


    # from_cli: log_path: "./sticky_elephant.log",
    #              port: 5432, host: '0.0.0.0',
    #              log_level: Logger::INFO,
    #              abort_on_exception: false
    def initialize(configuration_path = "./sticky_elephant.conf")
      conf                = YAML.load_file(configuration_path)
      @port               = conf.fetch(:port, 5432)
      @host               = conf.fetch(:host, '0.0.0.0')
      @debug              = conf.fetch(:debug, false)
      @log_path           = conf.fetch(:log_path, './sticky_elephant.log')
      @abort_on_exception = conf.fetch(:abort_on_exception, false)
      @hpf_host           = conf.fetch(:hpf_host)
      @hpf_port           = conf.fetch(:hpf_port, 10_000)
      @hpf_ident          = conf.fetch(:hpf_ident)
      @hpf_secret         = conf.fetch(:hpf_secret)
    end

    def log_level
      debug? ? Logger::DEBUG : Logger::INFO
    end
  end
end
