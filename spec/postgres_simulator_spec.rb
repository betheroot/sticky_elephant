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

  it "Should give the correct response to SET queries" do
    set_query_tests = [
      "set client_encoding to gbk;",
      "set client_encoding\nto gbk\n;",
      "set client_encoding = gbk;",
      "set client_encoding= gbk;",
      "set client_encoding=gbk;",
      "set client_encoding =gbk;",
      "set client_encoding ='gbk';",
    ]

    aggregate_failures do
      expected = "S\x00\x00\x00\x19client_encoding\x00gbk;\x00C\x00\x00\x00\bSET\x00Z\x00\x00\x00\x05I".force_encoding("ASCII-8BIT")
      set_query_tests.each do |test_str|
        expect(StickyElephant::PostgresSimulator.new(test_str).response).to eq expected
      end
    end

  end
end
