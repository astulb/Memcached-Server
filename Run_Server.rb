#!/usr/bin/env ruby
require_relative "./MemcachedServer.rb"

begin
  server MemcachedServer.new().start
end
