module StickyElephant
  class ElephantLogger
    def initialize
      @text = Logger.new("sticky_elephant.log")
      @hpfeeds = ::HPFeeds::Client.new({
        host:   ENV.fetch('HPF_HOST'),
        port:   ENV.fetch('HPF_PORT', 10_000),
        ident:  ENV.fetch('HPF_IDENT'),
        secret: ENV.fetch('HPF_SECRET')
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
