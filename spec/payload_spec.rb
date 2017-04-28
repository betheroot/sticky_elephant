require "spec_helper"

describe StickyElephant::Payload do
  let(:query) do
    # "Q\x00\x00\x00\x1Aselect * from camels;\x00"
    StickyElephant::Payload.new([
      81, 0, 0, 0, 26, 115, 101, 108, 101, 99,
      116, 32, 42, 32, 102, 114, 111, 109, 32,
      99, 97, 109, 101, 108, 115, 59, 0
    ])
  end

  let(:invalid_payloads) do
    [
      invalid_query_length,
      StickyElephant::Payload.new([88]),
      StickyElephant::Payload.new([88, 0, 0, 0, 3]),
    ]
  end

  let(:invalid_query_length) do
    StickyElephant::Payload.new([
      81, 0, 0, 0, 25, 115, 101, 108, 101, 99,
      116, 32, 42, 32, 102, 114, 111, 109, 32,
      99, 97, 109, 101, 108, 115, 59, 0
    ])
  end

  describe("#to_s") do
    it do
      expect(query.to_s).to eq 'QUERY: \'select * from camels;\''
    end
  end

  describe "#type" do
    it "correctly sets :query" do
      expect(query.type).to eq :query
    end

    it "correctly sets :invalid" do
      aggregate_failures do
        invalid_payloads.each do |payload|
          expect(payload.type).to eq :invalid
        end
      end
    end
  end
end
