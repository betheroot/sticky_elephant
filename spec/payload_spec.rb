require "spec_helper"
require 'pathname'

def fixture_dir
  Pathname(spec_dir.join('fixtures'))
end

def spec_dir
  Pathname(RSpec::Core::RubyProject.root).join('spec')
end

def fixture(pn)
  pathname = Pathname(pn)
  File.read(fixture_dir.join(pathname)).bytes
end


describe StickyElephant::Payload do
  let(:query) { StickyElephant::Payload.new(fixture('query.valid')) }
  let(:invalid_query_length) { StickyElephant::Payload.new(fixture('query.invalid')) }

  let(:invalid_payloads) do
    [
      invalid_query_length,
      StickyElephant::Payload.new([88]),
      StickyElephant::Payload.new([88, 0, 0, 0, 3]),
    ]
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
