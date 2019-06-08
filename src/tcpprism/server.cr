require "uri"
require "logger"
require "socket"

module TCPPrism
  class Server
    def initialize(listen : String, forward : String, mirror : String)
      @listen = URI.parse "tcp://#{listen}"
      @forward = URI.parse "tcp://#{forward}"
      @mirror = URI.parse "tcp://#{mirror}"
      @server = TCPServer.new(@listen.host.not_nil!, @listen.port.not_nil!)
      puts "Listening: #{@server.local_address}"
      puts "Forward: #{@forward}"
      puts "Mirror: #{@mirror}"
    end

    def run
      while client = @server.accept?
        spawn handle_client(client)
      end
    end

    def handle_client(client)
      socket_options(client)

      log = Logger.new(STDOUT, progname: client.remote_address.to_s)
      log.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << "[" << progname << "] " << severity.to_s.rjust(5) << " " << message
      end
      log.info "Connected"

      begin
        f = TCPSocket.new(@forward.host.not_nil!, @forward.port.not_nil!, connect_timeout: 5)
        socket_options(f)
        spawn forward_to_client(client, f, log)
      rescue ex
        log.error ex.message
        client.close
        log.info "Disconnected"
        return
      end

      begin
        m = TCPSocket.new(@mirror.host.not_nil!, @mirror.port.not_nil!, connect_timeout: 5)
        socket_options(m)
        spawn empty_read(m, log)
      rescue ex
        log.error ex.message
        m = nil
      end

      spawn client_to_both(client, f, m, log)
    end

    private def client_to_both(client, f, m, log)
      buffer = uninitialized UInt8[16384]
      loop do
        len = client.read(buffer.to_slice)
        break if len.zero?
        begin
          f.write buffer.to_slice[0, len]
        rescue ex
          log.error "Write to forward: #{ex.inspect}" unless f.closed?
          break
        end
        begin
          m.write(buffer.to_slice[0, len])
        rescue ex
          log.error "Write to mirror: #{ex.inspect}" unless m.closed?
          m.try &.close
          m = nil
        end if m
      end
    rescue ex
      log.error "Reading from client: #{ex.inspect}" unless client.closed?
    ensure
      log.info "Disconnected"
      client.close
      f.close
      m.try &.close
    end

    private def forward_to_client(client, f, log)
      buffer = uninitialized UInt8[16384]
      loop do
        len = f.read(buffer.to_slice)
        break if len.zero?
        begin
          client.write buffer.to_slice[0, len]
        rescue ex
          log.error "Write to client: #{ex.inspect}" unless client.closed?
          break
        end
      end
      log.error "Forward disconnected"
    rescue ex
      log.error "Reading from forward: #{ex.inspect}" unless f.closed?
    ensure
      client.close
      f.close
    end

    private def empty_read(m, log)
      buffer = uninitialized UInt8[16384]
      loop do
        len = m.read(buffer.to_slice)
        break if len.zero?
      end
      log.error "Mirror disconnected"
    rescue ex
      log.error "Reading from mirror: #{ex.inspect}" unless m.closed?
    ensure
      m.close
    end

    private def socket_options(socket)
      socket.sync = true
      socket.read_buffering = false
      socket.write_timeout = 5
    end
  end
end
