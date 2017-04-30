module StickyElephant
  module Handler
    class Query < Base
      def process
        log(msg: "#{payload}", level: :info)
        report_query(payload.to_s)

        socket.write(
          PostgresSimulator.new(
            extract_query_from(payload)
          )
        )
      end

      private

      def extract_query_from(payload)
        payload.to_s(with_type: false)
      end
    end
  end
end
