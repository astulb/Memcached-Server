#!/usr/bin/env ruby
require "socket"
require "securerandom"
require "./Config.rb"
require "./Value.rb"

class MemcachedServer
  attr_writer :server
  attr_writer :port
  attr_accessor :storage

  def initialize()
    @port = Config::PORT
    @ip = Config::IP
    @storage = {}
    @semaphore = Mutex.new
  end

  #Starts the server
  def start()
    @server = TCPServer.new(@ip, @port)
    begin
      puts "server running"
      loop {
        Thread.start(@server.accept) do |client|
          client.puts "CONNECTED\r\n"
          while request = client.gets
            if request.chomp == "quit"
              break
            end
            response = process_request(request.chomp, client)
            client.puts response
          end
          client.close
        end
      }
    rescue Errno::ECONNRESET, Errno::EPIPE => e
      puts e.message
      retry
    end
  end

  def process_request(request, client)
    segmentedRequest = request.split
    case segmentedRequest[0]
    when "get"
      return process_get(segmentedRequest)
    when "gets"
      process_gets(segmentedRequest)
    when "set"
      return process_set(segmentedRequest, client)
    when "add"
      process_add(segmentedRequest, client)
    when "replace"
      process_replace(segmentedRequest, client)
    when "append"
      process_append(segmentedRequest, client)
    when "prepend"
      process_prepend(segmentedRequest, client)
    when "cas"
      process_cas(segmentedRequest, client)
    else
      return "\nERROR\r\n"
    end
  end

  #Checks existance and clears expired keys
  #Returns true if the key exist
  #Returns false if the key doesnt exist or has expired
  def exists(key)
    if @storage[key]
      return expired_cleaner(key)
    else
      return false
    end
  end

  #Returns true if the key isnt expired.
  def expired_cleaner(key)
    value = @storage[key]
    if value.ttl != 0 && value.storageDate + value.ttl < Time.now
      @storage.delete(key)
      return false
    end
    return true
  end

  #Process get requests
  def process_get(segmentedRequest)
    response = ""
    if segmentedRequest.length > 1
      @semaphore.synchronize do
        for i in 1..segmentedRequest.length - 1
          if exists(segmentedRequest[i])
            value = @storage[segmentedRequest[i]]
            response += "VALUE #{segmentedRequest[i]} #{value.flags} #{value.data.bytesize}\r\n"
            response += "#{value.data}\r\n"
          end
        end
      end
      response += "END\r\n"
    else
      response += "CLIENT_ERROR | NO KEYS\r\n"
    end
    return response
  end

  #Process gets requests
  def process_gets(segmentedRequest)
    response = ""
    if segmentedRequest.length > 1
      @semaphore.synchronize do
        for i in 1..segmentedRequest.length - 1
          if exists(segmentedRequest[i])
            value = @storage[segmentedRequest[i]]
            response += "VALUE #{segmentedRequest[i]} #{value.flags} #{value.data.bytesize} #{value.cas}\r\n"
            response += "#{value.data}\r\n"
          end
        end
      end
      response += "END\r\n"
    else
      response += "CLIENT_ERROR | NO KEYS\r\n"
    end
    return response
  end

  #Process set requests
  def process_set(segmentedRequest, client)
    response = ""
    if segmentedRequest.length == 5
      key = segmentedRequest[1]

      newValue = Value.new
      newValue.flags = segmentedRequest[2].to_i
      newValue.ttl = segmentedRequest[3].to_i
      bytes = segmentedRequest[4].to_i
      data = client.gets
      chompedData = data.chomp
      if chompedData.bytesize == bytes
        newValue.data = chompedData
        @semaphore.synchronize do
          newValue.storageDate = Time.now
          @storage[key] = newValue
          response += "STORED\r\n"
        end
      else
        response += "CLIENT_ERROR | INCORRECT DATA LENGTH\r\n"
      end
    else
      response += "CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n"
    end
    return response
  end

  #Process add requests
  def process_add(segmentedRequest, client)
    response = ""
    if segmentedRequest.length == 5
      key = segmentedRequest[1]
      @semaphore.synchronize do
        if !exists(key)
          newValue = Value.new
          newValue.flags = segmentedRequest[2].to_i
          newValue.ttl = segmentedRequest[3].to_i
          bytes = segmentedRequest[4].to_i
          data = client.gets
          chompedData = data.chomp
          if chompedData.bytesize == bytes
            newValue.data = chompedData
            newValue.storageDate = Time.now
            @storage[key] = newValue
            response += "STORED\r\n"
          else
            response += "CLIENT_ERROR | INCORRECT DATA LENGTH\r\n"
          end
        else
          response += "NOT_STORED\r\n"
        end
      end
    else
      response += "CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n"
    end
    return response
  end

  #Process replace requests
  def process_replace(segmentedRequest, client)
    response = ""
    if segmentedRequest.length == 5
      key = segmentedRequest[1]
      @semaphore.synchronize do
        if exists(key)
          newValue = Value.new
          newValue.flags = segmentedRequest[2].to_i
          newValue.ttl = segmentedRequest[3].to_i
          bytes = segmentedRequest[4].to_i
          data = client.gets
          chompedData = data.chomp
          if chompedData.bytesize == bytes
            newValue.data = chompedData
            newValue.storageDate = Time.now
            @storage[key] = newValue
            response += "STORED\r\n"
          else
            response += "CLIENT_ERROR | INCORRECT DATA LENGTH\r\n"
          end
        else
          response += "NOT_STORED\r\n"
        end
      end
    else
      response += "CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n"
    end
    return response
  end

  #Process append requests
  def process_append(segmentedRequest, client)
    response = ""
    if segmentedRequest.length == 5
      key = segmentedRequest[1]
      @semaphore.synchronize do
        if exists(key)
          valueToUpdate = @storage[key]
          valueToUpdate.flags = segmentedRequest[2].to_i
          valueToUpdate.ttl = segmentedRequest[3].to_i
          valueToUpdate.cas = rand(2 ** 64)
          bytes = segmentedRequest[4].to_i
          data = client.gets
          chompedData = data.chomp
          if chompedData.bytesize == bytes
            valueToUpdate.data.concat(chompedData)
            valueToUpdate.storageDate = Time.now
            @storage[key] = valueToUpdate
            response += "STORED\r\n"
          else
            response += "CLIENT_ERROR | INCORRECT DATA LENGTH\r\n"
          end
        else
          response += "NOT_STORED\r\n"
        end
      end
    else
      response += "CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n"
    end
    return response
  end

  #Process prepend requests
  def process_prepend(segmentedRequest, client)
    response = ""
    if segmentedRequest.length == 5
      key = segmentedRequest[1]
      @semaphore.synchronize do
        if exists(key)
          valueToUpdate = @storage[key]
          valueToUpdate.flags = segmentedRequest[2].to_i
          valueToUpdate.ttl = segmentedRequest[3].to_i
          valueToUpdate.cas = rand(2 ** 64)
          bytes = segmentedRequest[4].to_i
          data = client.gets
          chompedData = data.chomp
          if chompedData.bytesize == bytes
            valueToUpdate.data.prepend(chompedData)
            valueToUpdate.storageDate = Time.now
            @storage[key] = valueToUpdate
            response += "STORED\r\n"
          else
            response += "CLIENT_ERROR | INCORRECT DATA LENGTH\r\n"
          end
        else
          response += "NOT_STORED\r\n"
        end
      end
    else
      response += "CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n"
    end
    return response
  end

  #Process cas requests
  def process_cas(segmentedRequest, client)
    response = ""
    if segmentedRequest.length == 6
      key = segmentedRequest[1]
      @semaphore.synchronize do
        if exists(key)
          valueToUpdate = @storage[key]
          if valueToUpdate.cas == segmentedRequest[5].to_i
            valueToUpdate.flags = segmentedRequest[2].to_i
            valueToUpdate.ttl = segmentedRequest[3].to_i
            valueToUpdate.cas = rand(2 ** 64)
            bytes = segmentedRequest[4].to_i
            data = client.gets
            chompedData = data.chomp
            if chompedData.bytesize == bytes
              valueToUpdate.data = chompedData
              valueToUpdate.storageDate = Time.now
              @storage[key] = valueToUpdate
              response += "STORED\r\n"
            else
              response += "CLIENT_ERROR | INCORRECT DATA LENGTH\r\n"
            end
          else
            response += "EXISTS\r\n"
          end
        else
          response += "NOT_FOUND\r\n"
        end
      end
    else
      response += "CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n"
    end
    return response
  end
end
