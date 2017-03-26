require 'socket'
require 'optparse'
require 'logger'
require 'pp'

begin
  require 'pry-byebug'
rescue LoadError
  nil
end


require "sticky_elephant/version"
require "sticky_elephant/connection/base"
require "sticky_elephant/connection/handshake"
require "sticky_elephant/connection/query"
require "sticky_elephant/connection/ssl_request"
require "sticky_elephant/connection/null"
require "sticky_elephant/connection"
require "sticky_elephant/server"
require "sticky_elephant/cli"

module StickyElephant
end
