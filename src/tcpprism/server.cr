require "uri"
require "socket"

module TCPPrism
  class Server
    def initialize(listen : String, forward : String, mirror : String)
      p @listen = URI.parse "tcp://#{listen}"
      p @forward = URI.parse "tcp://#{forward}"
      p @mirror = URI.parse "tcp://#{mirror}"
      @server = TCPServer.new(@listen.host.not_nil!, @listen.port.not_nil!)
    end

    def run
      puts "Listening on #{@server.local_address}"
      while client = @server.accept?
        puts "Client connected #{client.remote_address}"
        spawn handle_client(client)
      end
    end

    def handle_client(client)
      client.sync = true
      client.read_buffering = false
      client.write_timeout = 5

      begin
        f = TCPSocket.new(@forward.host.not_nil!, @forward.port.not_nil!)
        f.sync = true
        f.read_buffering = false
        f.write_timeout = 5
      rescue ex
        puts ex.inspect
        client.close
        return
      end

      begin
        m = TCPSocket.new(@mirror.host.not_nil!, @mirror.port.not_nil!, connect_timeout = 5)
        m.sync = true
        m.read_buffering = false
        m.write_timeout = 5
      rescue ex
        puts ex.inspect
        m = nil
      end

      spawn client_to_both(client, f, m)
      spawn forward_to_client(client, f)
      spawn empty_read(m.not_nil!)
    end

    private def client_to_both(client, f, m)
      buffer = uninitialized UInt8[16384]
      loop do
        len = client.read(buffer.to_slice)
        break if len.zero?
        begin
          f.write buffer.to_slice[0, len] if f
        rescue ex
          puts ex.inspect
          client.close
          m.try &.close
          break
        end
        begin
          m.not_nil!.write(buffer.to_slice[0, len]) if m
        rescue ex
          puts ex.inspect
          m = nil
        end
      end
      puts "EOF on client"
    ensure
      client.close
      f.close
      m.close
    end

    private def forward_to_client(client, f)
      buffer = uninitialized UInt8[16384]
      loop do
        len = f.read(buffer.to_slice)
        break if len.zero?
        client.write buffer.to_slice[0, len]
      end
      puts "EOF on forward"
    rescue ex
      puts "forward_to_client:", ex.inspect
    ensure
      client.close
      f.close
    end

    private def empty_read(m : TCPSocket)
      buffer = uninitialized UInt8[16384]
      loop do
        len = m.read(buffer.to_slice)
        break if len.zero?
      end
      puts "EOF on mirror"
    rescue ex
      puts "empty_read:", ex.inspect
    ensure
      m.close
    end
  end
end
