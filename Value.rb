#!/usr/bin/env ruby

class Value
  attr_accessor :data, :ttl, :flags, :cas, :storageDate

  def initialize()
    @cas = rand(2 ** 64)
  end
end
