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
require "sticky_elephant/handler/base"
require "sticky_elephant/handler/handshake"
require "sticky_elephant/handler/query"
require "sticky_elephant/handler/ssl_request"
require "sticky_elephant/handler/null"
require "sticky_elephant/handler/error"
require "sticky_elephant/handler"
require "sticky_elephant/connection"
require "sticky_elephant/server"
require "sticky_elephant/cli"

module StickyElephant
end
