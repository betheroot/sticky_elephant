module StickyElephant
  module Handler
    class Quit < Base
      def self.validates?(payload)
        payload == [88, 0, 0, 0, 4]
      end

      def process
      end
    end
  end
end
