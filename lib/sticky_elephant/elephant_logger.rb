module StickyElephant
  class ElephantLogger
    def initialize(configuration)
      @text = Logger.new(configuration.log_path)
      @hpfeeds = ::HPFeeds::Client.new({
        host:   configuration.hpf_host,
        port:   configuration.hpf_port,
        ident:  configuration.hpf_ident,
        secret: configuration.hpf_secret
      })
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
      @hpfeeds.publish(payload, EVENT_CHANNELS.fetch(type))
    end

    def level=(lev)
      text.level = lev
    end

    def level
      text.level
    end

    def close
      text.close
    end

    private

    attr_reader :text

  end
end
