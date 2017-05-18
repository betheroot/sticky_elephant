require "spec_helper"

describe StickyElephant::PostgresProtocol do
  let(:protocol) do
    klass = class ProtocolDummy
              include StickyElephant::PostgresProtocol
            end
    klass.new
  end

  it "Should get 'T' messages right" do
    expected = fixture("row-description")
    expect(protocol.row_description('version').bytes).to eq expected
  end

  describe "#parameter_status" do
    parameter_status_tests =
      [
        {
          args: [:client_encoding, "GBK"],
          expected: "S\x00\x00\x00\x18client_encoding\x00GBK\x00"
        }
    ]
    parameter_status_tests.each do |h|
      it "Should respond correctly given arguments (#{h[:args].join(', ')})" do
        expect(protocol.parameter_status(*h[:args])).to eq h[:expected]
      end
    end

  end

  describe "#command_complete" do
    command_complete_tests =
      [
        {
          args: [:select, 1],
          expected: "C\x00\x00\x00\rSELECT 1\x00"
        },
        {
          args: [:set],
          expected: "C\x00\x00\x00\x08SET\x00"
        }
    ]
    command_complete_tests.each do |h|
      it "Should respond correctly given arguments (#{h[:args].join(', ')})" do
        expect(protocol.command_complete(*h[:args])).to eq h[:expected]
      end
    end
  end
end

