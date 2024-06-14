# ronin-masscan

[![CI](https://github.com/ronin-rb/ronin-masscan/actions/workflows/ruby.yml/badge.svg)](https://github.com/ronin-rb/ronin-masscan/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/ronin-rb/ronin-masscan.svg)](https://codeclimate.com/github/ronin-rb/ronin-masscan)

* [Website](https://ronin-rb.dev/)
* [Source](https://github.com/ronin-rb/ronin-masscan)
* [Issues](https://github.com/ronin-rb/ronin-masscan/issues)
* [Documentation](https://ronin-rb.dev/docs/ronin-masscan)
* [Discord](https://discord.gg/6WAb3PsVX9) |
  [Mastodon](https://infosec.exchange/@ronin_rb)

## Description

ronin-masscan is a Ruby library and CLI for working with masscan.

## Features

* Supports automating `masscan` using [ruby-masscan].
* Supports parsing and filtering masscan scan files.
* Supports converting masscan scan files into JSON or CSV.
* Supports importing masscan scan files into the [ronin-db] database.

## Synopsis

```
Usage: ronin-masscan [options]

Options:
    -V, --version                    Prints the version and exits
    -h, --help                       Print help information

Arguments:
    [COMMAND]                        The command name to run
    [ARGS ...]                       Additional arguments for the command

Commands:
    completion
    convert
    dump
    grep
    help
    import
    new
    print
    scan
```

Import a binary `masscan` scan file:

```shell
$ ronin-masscan import masscan.bin
```

Perform a masscan scan and import it's results into the [ronin-db]\:

```shell
$ ronin-masscan scan --import -- 192.168.1.1 -p22,25,80,443
```

Parse and filter an nmap XML scan file:

Import a JSON `masscan` scan file:

```shell
$ ronin-masscan import masscan.json
```

Dumps a masscan scan file to a list of `IP:PORT` pairs:

```shell
$ ronin-masscan dump --print-ip-ports masscan.bin
```

Dump a masscan scan file to a list of `HOST:PORT` pairs:

```shell
$ ronin-masscan dump --print-host-ports masscan.bin
```

Dump a masscan scan file to a list of `http`://` or `https://` URIs:

```shell
$ ronin-masscan dump --print-uris masscan.bin
```

Convert a binary `masscan` scan file to CSV:

```shell
$ ronin-masscan convert masscan.bin masscan.csv
```

Convert a binary `masscan` scan file to JSON:

```shell
$ ronin-masscan convert masscan.bin masscan.json
```

Generate a new masscan scanner Ruby script:

```shell
$ ronin-masscan new scanner.rb --ips '192.168.1.*' --ports 22,80,443,8000-9000
```

Generate a new masscan output file parser script:

```shell
$ ronin-masscan new parser.rb --parser --xml-file path/to/masscan.bin --printing
```

## Examples

```ruby
require 'ronin/masscan'

output_file = Ronin::Masscan.scan('192.168.1.1', ports: [80,443])
# => #<Masscan::OutputFile:...>

output_file = Ronin::Masscan.scan do |masscan|
  masscan.ports = [80,443]
  masscan.ips   = '192.168.1.1'
end
# => #<Masscan::OutputFile:...>
```

Accessing the masscan scan data:

```ruby
output_file.each do |record|
  p record
end
```

```
#<struct Masscan::Status status=:open, protocol=:tcp, port=80, reason=[:syn, :ack], ttl=54, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:33 -0700, mac=nil>
#<struct Masscan::Status status=:open, protocol=:tcp, port=443, reason=[:syn, :ack], ttl=54, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:33 -0700, mac=nil>
#<struct Masscan::Status status=:open, protocol=:icmp, port=0, reason=[], ttl=54, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:33 -0700, mac=nil>
#<struct Masscan::Banner protocol=:tcp, port=443, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:35 -0700, app_protocol=:ssl3, payload="TLS/1.1 cipher:0xc013, www.example.org, www.example.org, example.com, example.edu, example.net, example.org, www.example.com, www.example.edu, www.example.net">
#<struct Masscan::Banner protocol=:tcp, port=443, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:35 -0700, app_protocol=:x509_cert, payload="MIIG1TCCBb2gAwIBAgIQD74IsIVNBXOKsMzhya/uyTANBgkqhkiG9w0BAQsFADBPMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMSkwJwYDVQQDEyBEaWdpQ2VydCBUTFMgUlNBIFNIQTI1NiAyMDIwIENBMTAeFw0yMDExMjQwMDAwMDBaFw0yMTEyMjUyMzU5NTlaMIGQMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLTG9zIEFuZ2VsZXMxPDA6BgNVBAoTM0ludGVybmV0IENvcnBvcmF0aW9uIGZvciBBc3NpZ25lZCBOYW1lcyBhbmQgTnVtYmVyczEYMBYGA1UEAxMPd3d3LmV4YW1wbGUub3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuvzuzMoKCP8Okx2zvgucA5YinrFPEK5RQP1TX7PEYUAoBO6i5hIAsIKFmFxtW2sghERilU5rdnxQcF3fEx3sY4OtY6VSBPLPhLrbKozHLrQ8ZN/rYTb+hgNUeT7NA1mP78IEkxAj4qG5tli4Jq41aCbUlCt7equGXokImhC+UY5IpQEZS0tKD4vu2ksZ04Qetp0k8jWdAvMA27W3EwgHHNeVGWbJPC0Dn7RqPw13r7hFyS5TpleywjdY1nB7ad6kcZXZbEcaFZ7ZuerA6RkPGE+PsnZRb1oFJkYoXimsuvkVFhWeHQXCGC1cuDWSrM3cpQvOzKH2vS7d15+zGls4IwIDAQABo4IDaTCCA2UwHwYDVR0jBBgwFoAUt2ui6qiqhIx56rTaD5iyxZV2ufQwHQYDVR0OBBYEFCYa+OSxsHKEztqBBtInmPvtOj0XMIGBBgNVHREEejB4gg93d3cuZXhhbXBsZS5vcmeCC2V4YW1wbGUuY29tggtleGFtcGxlLmVkdYILZXhhbXBsZS5uZXSCC2V4YW1wbGUub3Jngg93d3cuZXhhbXBsZS5jb22CD3d3dy5leGFtcGxlLmVkdYIPd3d3LmV4YW1wbGUubmV0MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwgYsGA1UdHwSBgzCBgDA+oDygOoY4aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VExTUlNBU0hBMjU2MjAyMENBMS5jcmwwPqA8oDqGOGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv">
#<struct Masscan::Banner protocol=:tcp, port=80, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:35 -0700, app_protocol=:http_server, payload="ECS (sec/97A6)">
#<struct Masscan::Banner protocol=:tcp, port=80, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:35 -0700, app_protocol=:html_title, payload="404 - Not Found">
#<struct Masscan::Banner protocol=:tcp, port=80, ip=#<IPAddr: IPv4:93.184.216.34/255.255.255.255>, timestamp=2021-08-26 16:07:35 -0700, app_protocol=:http, payload="HTTP/1.0 404 Not Found\r\nContent-Type: text/html\r\nDate: Thu, 26 Aug 2021 23:07:35 GMT\r\nServer: ECS (sec/97A6)\r\nContent-Length: 345\r\nConnection: close\r\n\r">
```

## Requirements

* [Ruby] >= 3.0.0
* [masscan] >= 1.0.0
* [ruby-masscan] ~> 0.1
* [ronin-core] ~> 0.2
* [ronin-db] ~> 0.2

## Install

```shell
$ gem install ronin-masscan
```

### Gemfile

```ruby
gem 'ronin-masscan', '~> 0.1'
```

### gemspec

```ruby
gem.add_dependency 'ronin-masscan', '~> 0.1'
```

## Development

1. [Fork It!](https://github.com/ronin-rb/ronin-masscan/fork)
2. Clone It!
3. `cd ronin-masscan/`
4. `./scripts/setup`
5. `git checkout -b my_feature`
6. Code It!
7. `bundle exec rake spec`
8. `git push origin my_feature`

## License

Copyright (c) 2023-2024 Hal Brodigan (postmodern.mod3@gmail.com)

ronin-masscan is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ronin-masscan is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with ronin-masscan.  If not, see <https://www.gnu.org/licenses/>.

[Ruby]: https://www.ruby-lang.org
[masscan]: https://github.com/robertdavidgraham/masscan#readme
[ruby-masscan]: https://github.com/postmodern/ruby-masscan#readme
[ronin-support]: https://github.com/ronin-rb/ronin-support#readme
[ronin-core]: https://github.com/ronin-rb/ronin-core#readme
[ronin-db]: https://github.com/ronin-rb/ronin-db#readme
