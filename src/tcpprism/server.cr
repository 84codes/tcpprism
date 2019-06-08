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

      spawn do
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
      end
      spawn do
        buffer = uninitialized UInt8[16384]
        loop do
          len = f.read(buffer.to_slice)
          break if len.zero?
          client.write buffer.to_slice[0, len]
        rescue ex
          puts ex.inspect
          f.close if f
          client.close
          break
        end
      end
      spawn do
        buffer = uninitialized UInt8[16384]
        loop do
          break unless m
          len = m.not_nil!.read(buffer.to_slice)
          break if len.zero?
        rescue ex
          puts ex.inspect
          m = nil
        end
      end
    end
  end
end
