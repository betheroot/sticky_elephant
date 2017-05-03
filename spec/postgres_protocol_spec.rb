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
end

