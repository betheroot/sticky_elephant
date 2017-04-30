$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sticky_elephant"
require 'util/fixture_helper'
RSpec.configure do |c|
  c.include FixtureHelper
end
