require "./spec_helper"

describe TCPPrism do
  it "works" do
    f = TCPServer.new("localhost", 0)
    while client = f.accept?
      spawn handle_client(client)
    end
    m = TCPServer.new("localhost", 0)
    prism = TCPPrism.new("localhost:0")
    prism.local_address.port
    TCPSocket.new

  end
end
