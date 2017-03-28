module StickyElephant
  class ElephantLogger
    def initialize
      @text = Logger.new("sticky_elephant.log")
    end

    %i(debug info warn error fatal unknown).each do |level|
      define_method(level) do |*args, &block|
        @text.send(level, *args, &block)
      end
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
