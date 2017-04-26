module StickyElephant
  class ElephantLogger
    def initialize(configuration)
      @text = Logger.new(configuration.log_path)
      @text.level = configuration.log_level
      begin
        @hpfeeds = if configuration.use_hpfeeds?
                     new_hpfeeds_connection(configuration)
                   else
                     null_hpfeeds_connection
                   end
      rescue => e
        warn("#{e.class} received from hpfeeds: #{e}")
        raise e
      end
    end

    %i(debug info warn error fatal unknown).each do |level|
      define_method(level) do |*args, &block|
        @text.send(level, *args, &block)
      end
    end

    EVENT_CHANNELS = {
      connection: 'sticky_elephant.connections',
      query: 'sticky_elephant.queries',
    }.freeze

    def event(type, payload)
      unless EVENT_CHANNELS.keys.include? type
        raise ArgumentError.new("Event type #{type} not in #{EVENT_CHANNELS.keys.join(',')}")
      end
      begin
        hpfeeds.publish(payload, EVENT_CHANNELS.fetch(type))
      rescue => e
        warn("#{e.class} received from hpfeeds: #{e}")
      end
    end

    def close
      text.close
      hpfeeds.close
    end

    private

    attr_reader :text, :hpfeeds

    def new_hpfeeds_connection(configuration)
      ::HPFeeds::Client.new(
        host:   configuration.hpf_host,
        port:   configuration.hpf_port,
        ident:  configuration.hpf_ident,
        secret: configuration.hpf_secret,
        reconnect: false
      )
    end

    def null_hpfeeds_connection
      @null_hpfeeds_klass ||= Struct.new('NullHPFeedsConnection') do
        def noop(*args) ; end
        alias_method :close, :noop
        alias_method :publish, :noop
      end
      @null_hpfeeds_connection ||= @null_hpfeeds_klass.new
    end
  end
end
