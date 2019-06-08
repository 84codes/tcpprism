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

Eg.:

```
ulimit -n 16384
tcpprism --listen 0.0.0.0:80 --forward 127.0.0.1:8080 --mirror 10.0.0.2:8080
```

## Contributing

1. Fork it (<https://github.com/84codes/tcpprism/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Carl Hörberg](https://github.com/carlhoerberg) - creator and maintainer
