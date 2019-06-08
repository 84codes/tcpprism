require "option_parser"
require "./tcpprism/*"

module TCPPrism
  def self.cli
    listen = ""
    forward = ""
    mirror = ""
    OptionParser.parse! do |parser|
      parser.banner = "Usage: tcpprism [arguments]"
      parser.on("-l", "--listen=ADDR", "Address and port to listen on") { |v| listen = v }
      parser.on("-f", "--forward=ADDR", "Address and port to forward traffic to") { |v| forward = v }
      parser.on("-m", "--mirror=ADDR", "Address and port to mirror traffic to") { |v| mirror = v }
      parser.on("-h", "--help", "Show this help") { puts parser; exit }
      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option."
        STDERR.puts parser
        exit(1)
      end
    end
    s = Server.new(listen, forward, mirror)
    s.run
  end
end

TCPPrism.cli
