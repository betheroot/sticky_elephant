require "spec_helper"

describe StickyElephant::PostgresSimulator do
  let(:version_sim) { StickyElephant::PostgresSimulator.new("SELECT version();") }
  let(:conf_sim) { StickyElephant::PostgresSimulator.new("SELECT current_setting('config_file');") }

  it "Should respond with the version" do
    expected = fixture("version-response")
    expect(version_sim.response.bytes).to eq expected
  end

  it "Should respond with path to the config file" do
    expected = fixture("current-setting-response")
    expect(conf_sim.response.bytes).to eq expected
  end
end
