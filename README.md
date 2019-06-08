# TCPPrism

Mirrors TCP traffic between a `client` and a `forward` host, but also sends the same traffic to a `mirror` host. The response from the `mirror` is thrown away.

## Installation

From source:

```
git clone https://github.com/84codes/tcpprism.git
cd tcpprism
shards build --release --production
install bin/tcpprism /usr/local/bin/
```

Or [download precompiled binaries](https://github.com/84codes/tcpprism/releases).

## Usage

```
Usage: tcpprism [arguments]
    -l, --listen=ADDR                Address and port to listen on (required)
    -f, --forward=ADDR               Address and port to forward traffic to (required)
    -m, --mirror=ADDR                Address and port to mirror traffic to (required)
    -h, --help                       Show this help
```

If you for example would like to mirror the traffic currently coming in to a
server on port 80, to another server also running on port 80, but without
stopping and changing port of the original server, you can use trick with
iptables that redirects port 80 to the `tcpprism` server, which in turn will
forward the traffic to both the original server and the server on the other
host.

```sh
ulimit -n 16384
iptables -t nat -A PREROUTING -i ens5 -p tcp --dport 80 -j REDIRECT --to-port 8080
tcpprism --listen 0.0.0.0:8080 --forward 127.0.0.1:80 --mirror 10.0.0.2:80
```
## Contributing

1. Fork it (<https://github.com/84codes/tcpprism/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Carl Hörberg](https://github.com/carlhoerberg) - creator and maintainer
