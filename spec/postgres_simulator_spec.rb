require "spec_helper"

describe StickyElephant::PostgresSimulator do
  let(:version_sim) { StickyElephant::PostgresSimulator.new("SELECT version();") }
  it "Should respond with the version" do
    expected = fixture("version-response")
    expect(version_sim.response.bytes).to eq expected
  end
end
