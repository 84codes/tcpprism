require "uri"
require "socket"
require "option_parser"

module TCPPrism
  VERSION = "0.1.0"

  class Server
    def self.cli
      listen = ""
      forward = ""
      mirror = ""
      OptionParser.parse! do |parser|
        parser.banner = "Usage: tcpprism [arguments]"
        parser.on("-l", "--listen", "Address and port to listen on") { |v| listen = v }
        parser.on("-f", "--forward", "Address and port to forward traffic to") { |v| forward = v }
        parser.on("-m", "--mirror", "Address and port to mirror traffic to") { |v| mirror = v }
        parser.on("-h", "--help", "Show this help") { puts parser; exit }
        parser.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option."
          STDERR.puts parser
          exit(1)
        end
      end
      new(listen, forward, mirror)
    end


    def initialize(listen, forward, mirror)
      @listen = URI.parse "tcp://#{listen}"
      @forward = URI.parse "tcp://#{forward}"
      @mirror = URI.parse "tcp://#{mirror}"
    end

    def run
      server = TCPServer.new(@listen.host, @listen.port)
      while client = server.accept?
        spawn handle_client(client)
      end
    end

    def handle_client(client)
      f = TCPSocket.new(@forward.host, @forward.port)
      m = TCPSocket.new(@mirror.host, @mirror.port)
      spawn do
        buffer = uninitialized UInt8[16384]
        loop do
          len = client.read(buffer.to_slice)
          f.write buffer.to_slice[0, len]
          m.write buffer.to_slice[0, len]
        end
      end
      spawn do
        buffer = uninitialized UInt8[16384]
        loop do
          len = f.read(buffer.to_slice)
          client.write buffer.to_slice[0, len]
        end
      end
      spawn do
        buffer = uninitialized UInt8[16384]
        loop do
          m.read(buffer.to_slice)
        end
      end
    end
  end
end
