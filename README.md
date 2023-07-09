# ronin-masscan

[![CI](https://github.com/ronin-rb/ronin-masscan/actions/workflows/ruby.yml/badge.svg)](https://github.com/ronin-rb/ronin-masscan/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/ronin-rb/ronin-masscan.svg)](https://codeclimate.com/github/ronin-rb/ronin-masscan)

* [Website](https://ronin-rb.dev/)
* [Source](https://github.com/ronin-rb/ronin-masscan)
* [Issues](https://github.com/ronin-rb/ronin-masscan/issues)
* [Documentation](https://ronin-rb.dev/docs/ronin-masscan)
* [Discord](https://discord.gg/6WAb3PsVX9) |
  [Twitter](https://twitter.com/ronin_rb) |
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
    convert
    help
    import
    scan
    targets
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

Convert an masscan scan file to a list of `IP:PORT` pairs:

```shell
$ ronin-masscan targets --print-ip-ports masscan.bin
```

Convert an masscan scan file to a list of `HOST:PORT` pairs:

```shell
$ ronin-masscan targets --print-host-ports masscan.bin
```

Convert an masscan scan file to a list of `http`://` or `https://` URIs:

```shell
$ ronin-masscan targets --print-uris masscan.bin
```

Convert a binary `masscan` scan file to CSV:

```shell
$ ronin-masscan convert masscan.bin masscan.csv
```

Convert a binary `masscan` scan file to JSON:

```shell
$ ronin-masscan convert masscan.bin masscan.json
```

## Requirements

* [Ruby] >= 3.0.0
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
4. `bundle install`
5. `git checkout -b my_feature`
6. Code It!
7. `bundle exec rake spec`
8. `git push origin my_feature`

## License

Copyright (c) 2023 Hal Brodigan (postmodern.mod3@gmail.com)

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
[ruby-masscan]: https://github.com/postmodern/ruby-masscan#readme
[ronin-support]: https://github.com/ronin-rb/ronin-support#readme
[ronin-core]: https://github.com/ronin-rb/ronin-core#readme
[ronin-db]: https://github.com/ronin-rb/ronin-db#readme
