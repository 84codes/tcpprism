require "option_parser"
require "./tcpprism/*"

module TCPPrism
  def self.cli
    listen = ""
    forward = ""
    mirror = ""
    parser = OptionParser.new do |parser|
      parser.banner = "Usage: tcpprism [arguments]"
      parser.on("-l", "--listen=ADDR", "Address and port to listen on (required)") { |v| listen = v }
      parser.on("-f", "--forward=ADDR", "Address and port to forward traffic to (required)") { |v| forward = v }
      parser.on("-m", "--mirror=ADDR", "Address and port to mirror traffic to (required)") { |v| mirror = v }
      parser.on("-h", "--help", "Show this help") { puts parser; exit }
      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option."
        abort parser
      end
      parser.missing_option do |flag|
        STDERR.puts "ERROR: #{flag} requires a value, eg. localhost:1234"
        abort parser
      end
    end
    parser.parse!
    if listen.empty? || forward.empty? || mirror.empty?
      STDERR.puts "Required argument missing"
      abort parser
    end
    Server.new(listen, forward, mirror).run
  end
end

TCPPrism.cli
