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
  let(:invalid_query) { StickyElephant::Payload.new(fixture('query.invalid')) }
  let(:ssl_request) { StickyElephant::Payload.new(fixture('ssl_request.valid'))}
  let(:invalid_ssl_request) { StickyElephant::Payload.new(fixture('ssl_request.invalid'))}
  let(:quit) { StickyElephant::Payload.new(fixture('quit.valid'))}

  let(:invalid_payloads) do
    [
      invalid_query,
      invalid_ssl_request,
      StickyElephant::Payload.new([88]),
      StickyElephant::Payload.new([88, 0, 0, 0, 3]),
    ]
  end

  describe("#to_s") do
    context "Query" do
      it "Returns the appropriate string" do
        expect(query.to_s).to eq 'QUERY: \'select * from camels;\''
      end
    end
  end

  describe "#type" do
    it "returns the correct symbol" do
      aggregate_failures do
        expect(query.type).to eq :query
        expect(ssl_request.type).to eq :ssl_request
        expect(quit.type).to eq :quit
      end
    end

    context "Invalid requests" do
      it "correctly sets :invalid" do
        aggregate_failures do
          invalid_payloads.each do |payload|
            expect(payload.type).to eq :invalid
          end
        end
      end
    end
  end
end
