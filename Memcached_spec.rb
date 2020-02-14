require "./MemcachedServer"
require "./Value"

describe MemcachedServer do
  before :each do
    @server = MemcachedServer.new
  end

  describe ".process_get" do
    before :each do
      value1 = Value.new
      value1.ttl = 0
      value1.data = "Test Data 1"
      value1.flags = 0
      value1.storageDate = Time.now
      @server.storage["Key1"] = value1

      value2 = Value.new
      value2.ttl = 0
      value2.data = "Test Data 2"
      value2.flags = 0
      value2.storageDate = Time.now
      @server.storage["Key2"] = value2
    end

    context "When getting one key" do
      it "should respond with the key value" do
        request = "get Key1".split
        expect(@server.process_get(request)).to eq("VALUE Key1 0 11\r\nTest Data 1\r\nEND\r\n")
      end
    end

    context "When getting multiple keys" do
      it "should respond with every key value" do
        request = "get Key1 Key2".split
        expect(@server.process_get(request)).to eq("VALUE Key1 0 11\r\nTest Data 1\r\nVALUE Key2 0 11\r\nTest Data 2\r\nEND\r\n")
      end
    end

    context "When the key is not found" do
      it "should respond with nothing" do
        request = "get Key3".split
        expect(@server.process_get(request)).to eq("END\r\n")
      end
    end

    context "When the request is invalid" do
      it "should respond with NO KEYS" do
        request = "get ".split
        client = double("client")
        expect(@server.process_get(request)).to eq("CLIENT_ERROR | NO KEYS\r\n")
      end
    end
  end

  describe ".process_gets" do
    before :each do
      forcedCasValue = 1234567890

      value1 = Value.new
      value1.cas = 1234567890
      value1.ttl = 0
      value1.data = "Test Data 1"
      value1.flags = 0
      value1.storageDate = Time.now
      @server.storage["Key1"] = value1

      value2 = Value.new
      value2.cas = 1234567890
      value2.ttl = 0
      value2.data = "Test Data 2"
      value2.flags = 0
      value2.storageDate = Time.now
      @server.storage["Key2"] = value2
    end

    context "When getting one key" do
      it "should respond with the key value" do
        request = "gets Key1".split
        expect(@server.process_gets(request)).to eq("VALUE Key1 0 11 1234567890\r\nTest Data 1\r\nEND\r\n")
      end
    end

    context "When getting multiple keys" do
      it "should respond with every key value" do
        request = "gets Key1 Key2".split
        expect(@server.process_gets(request)).to eq("VALUE Key1 0 11 1234567890\r\nTest Data 1\r\nVALUE Key2 0 11 1234567890\r\nTest Data 2\r\nEND\r\n")
      end
    end

    context "When the key is not found" do
      it "should respond with nothing" do
        request = "gets Key3".split
        expect(@server.process_gets(request)).to eq("END\r\n")
      end
    end

    context "When the request is invalid" do
      it "should respond with NO KEYS" do
        request = "get ".split
        client = double("client")
        expect(@server.process_get(request)).to eq("CLIENT_ERROR | NO KEYS\r\n")
      end
    end
  end

  describe ".process_set" do
    context "When the request is valid" do
      before :each do
        value1 = Value.new
        value1.ttl = 0
        value1.data = "Test Data 1"
        value1.flags = 0
        value1.storageDate = Time.now
        @server.storage["Key1"] = value1
      end

      context "When setting a new key" do
        it "should respond with STORED" do
          request = "set newKey 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_set(request, client)).to eq("STORED\r\n")
        end
      end

      context "When setting an existing key" do
        it "should respond with STORED" do
          request = "set Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_set(request, client)).to eq("STORED\r\n")
        end
      end

      context "When sending more or less data than specified on the request" do
        it "should respond with INCORRECT DATA LENGTH" do
          request = "set Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testDataTOLONG")
          expect(@server.process_set(request, client)).to eq("CLIENT_ERROR | INCORRECT DATA LENGTH\r\n")
        end
      end
    end

    context "When the request is invalid" do
      it "should respond with CLIENT_ERROR" do
        request = "set  invalidArgument1 Key1 0 0 8 invalidArgument2".split
        client = double("client")
        expect(@server.process_set(request, client)).to eq("CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n")
      end
    end
  end

  describe ".process_add" do
    context "When the request is valid" do
      before :each do
        value1 = Value.new
        value1.ttl = 0
        value1.data = "Test Data 1"
        value1.flags = 0
        value1.storageDate = Time.now
        @server.storage["Key1"] = value1
      end

      context "When adding a new key" do
        it "should respond with STORED" do
          request = "add newKey 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_add(request, client)).to eq("STORED\r\n")
        end
      end

      context "When adding an existing key" do
        it "should respond with NOT STORED" do
          request = "add Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_add(request, client)).to eq("NOT_STORED\r\n")
        end
      end

      context "When sending more or less data than specified on the request" do
        it "should respond with INCORRECT DATA LENGTH" do
          request = "add newKey 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testDataTOLONG")
          expect(@server.process_add(request, client)).to eq("CLIENT_ERROR | INCORRECT DATA LENGTH\r\n")
        end
      end
    end

    context "When the request is invalid" do
      it "should respond with CLIENT_ERROR" do
        request = "add  invalidArgument1 Key1 0 0 8 invalidArgument2".split
        client = double("client")
        expect(@server.process_add(request, client)).to eq("CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n")
      end
    end
  end

  describe ".process_replace" do
    context "When the request is valid" do
      before :each do
        value1 = Value.new
        value1.ttl = 0
        value1.data = "Test Data 1"
        value1.flags = 0
        value1.storageDate = Time.now
        @server.storage["Key1"] = value1
      end

      context "When replacing a new key" do
        it "should respond with NOT_STORED" do
          request = "replace newKey 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_replace(request, client)).to eq("NOT_STORED\r\n")
        end
      end

      context "When replacing an existing key" do
        it "should respond with STORED" do
          request = "replace Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_replace(request, client)).to eq("STORED\r\n")
        end
      end

      context "When sending more or less data than specified on the request" do
        it "should respond with INCORRECT DATA LENGTH" do
          request = "replace Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testDataTOLONG")
          expect(@server.process_replace(request, client)).to eq("CLIENT_ERROR | INCORRECT DATA LENGTH\r\n")
        end
      end
    end

    context "When the request is invalid" do
      it "should respond with CLIENT_ERROR" do
        request = "replace  invalidArgument1 Key1 0 0 8 invalidArgument2".split
        client = double("client")
        expect(@server.process_replace(request, client)).to eq("CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n")
      end
    end
  end

  describe ".process_append" do
    context "When the request is valid" do
      before :each do
        value1 = Value.new
        value1.ttl = 0
        value1.data = "Test Data 1"
        value1.flags = 0
        value1.storageDate = Time.now
        @server.storage["Key1"] = value1
      end

      context "When appending on a new key" do
        it "should respond with NOT_STORED" do
          request = "append newKey 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_append(request, client)).to eq("NOT_STORED\r\n")
        end
      end

      context "When appending on an existing key" do
        it "should respond with STORED" do
          request = "append Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_append(request, client)).to eq("STORED\r\n")
        end
      end

      context "When sending more or less data than specified on the request" do
        it "should respond with INCORRECT DATA LENGTH" do
          request = "append Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testDataTOLONG")
          expect(@server.process_append(request, client)).to eq("CLIENT_ERROR | INCORRECT DATA LENGTH\r\n")
        end
      end
    end

    context "When the request is invalid" do
      it "should respond with CLIENT_ERROR" do
        request = "append  invalidArgument1 Key1 0 0 8 invalidArgument2".split
        client = double("client")
        expect(@server.process_add(request, client)).to eq("CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n")
      end
    end
  end

  describe ".process_prepend" do
    context "When the request is valid" do
      before :each do
        value1 = Value.new
        value1.ttl = 0
        value1.data = "Test Data 1"
        value1.flags = 0
        value1.storageDate = Time.now
        @server.storage["Key1"] = value1
      end

      context "When trying to prepend on a new key" do
        it "should respond with NOT_STORED" do
          request = "prepend newKey 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_prepend(request, client)).to eq("NOT_STORED\r\n")
        end
      end

      context "When trying to prepend on an existing key" do
        it "should respond with STORED" do
          request = "prepend Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_prepend(request, client)).to eq("STORED\r\n")
        end
      end

      context "When sending more or less data than specified on the request" do
        it "should respond with INCORRECT DATA LENGTH" do
          request = "prepend Key1 0 0 8".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testDataTOLONG")
          expect(@server.process_prepend(request, client)).to eq("CLIENT_ERROR | INCORRECT DATA LENGTH\r\n")
        end
      end
    end

    context "When the request is invalid" do
      it "should respond with CLIENT_ERROR" do
        request = "prepend  invalidArgument1 Key1 0 0 8 invalidArgument2".split
        client = double("client")
        expect(@server.process_prepend(request, client)).to eq("CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n")
      end
    end
  end

  describe ".process_cas" do
    context "When the request is valid" do
      before :each do
        forcedCasValue = 12345
        value1 = Value.new
        value1.cas = forcedCasValue
        value1.ttl = 0
        value1.data = "Test Data 1"
        value1.flags = 0
        value1.storageDate = Time.now
        @server.storage["Key1"] = value1
      end

      context "When trying cas on a new key" do
        it "should respond with NOT_FOUND" do
          request = "cas newKey 0 0 8 12345".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testData")
          expect(@server.process_cas(request, client)).to eq("NOT_FOUND\r\n")
        end
      end

      context "When trying cas on an existing key" do
        context "with a correct cas value" do
          it "should return STORED" do
            request = "cas Key1 0 0 8 12345".split
            client = double("client")
            allow(client).to receive(:gets).and_return("testData")
            expect(@server.process_cas(request, client)).to eq("STORED\r\n")
          end
        end

        context "with an incorrect cas value" do
          it "should return EXISTS" do
            request = "cas Key1 0 0 8 invalidCAS".split
            client = double("client")
            allow(client).to receive(:gets).and_return("testData")
            expect(@server.process_cas(request, client)).to eq("EXISTS\r\n")
          end
        end
      end

      context "When sending more or less data than specified on the request" do
        it "should respond with INCORRECT DATA LENGTH" do
          request = "cas Key1 0 0 8 12345".split
          client = double("client")
          allow(client).to receive(:gets).and_return("testDataTOLONG")
          expect(@server.process_cas(request, client)).to eq("CLIENT_ERROR | INCORRECT DATA LENGTH\r\n")
        end
      end
    end

    context "When the request is invalid" do
      it "should respond with CLIENT_ERROR" do
        request = "cas  invalidArgument1 Key1 0 0 8 invalidArgument2".split
        client = double("client")
        expect(@server.process_cas(request, client)).to eq("CLIENT_ERROR | MISSING OR EXTRA ARGUMENTS\r\n")
      end
    end
  end
end
