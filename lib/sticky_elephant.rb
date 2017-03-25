require 'socket'
require 'optparse'
require 'logger'

begin
  require 'pry-byebug'
rescue LoadError
  nil
end


require "sticky_elephant/version"
require "sticky_elephant/connection"
require "sticky_elephant/server"
require "sticky_elephant/cli"

module StickyElephant
end
