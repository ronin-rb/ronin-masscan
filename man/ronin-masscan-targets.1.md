# ronin-masscan-targets 1 "2023-03-01" Ronin "User Manuals"

## SYNOPSIS

`ronin-masscan targets` [options] *MASSCAN_FILE*

## DESCRIPTION

Converts  masscan scan files into a list of targets.

## ARGUMENTS

*MASSCAN_FILE*
: The masscan scan file to import.

## OPTIONS

`--print-ips`
: Only print the IP addresses of the targets (ex: `192.168.1.1`).

`--print-hosts`
: Only print the hostnames of the targets (ex: `example.com`).

`--print-ip-ports`
: Print IP address and port pairs for each target (ex: `192.168.1.1:443`).
  This is the default behavior.

`--print-host-ports`
: Print hostname and port pairs for each target (ex: `example.com:443`).

`--print-uris
: Print URIs for each target that has either `http` or `https` services
  (ex: `https://example.com` or `http://example.com:8080`).

`-P`, `--protocol` `tcp`|`udp`
: Filters the targets by the protocol of the open port.

`--ip` *IP*
: Filters the targets by a specific IP address.

`--ip-range` *CIDR*
: Filter the targets by a CIDR IP range (ex: `192.168.1.0/24`).

`-p`, `--ports` {*PORT* | *PORT1-PORT2*},...
: Filter `IP:PORT` or `HOST:PORT` pairs who's ports are in the gvien port list.
  The port list is a comma separated list of port numbers (`443`) or port
  ranges (`8000-9000`).

`-h`, `--help`
: Print help information

## EXAMPLES

Print `IP:PORT` pairs from the masscan scan file:

    ronin-masscan targets --print-ip-ports masscan.bin

Print `IP:PORT` pairs with ports 22, 80, or 443, from the masscan scan file:

    ronin-masscan targets --print-ip-ports --ports 22,80,443 masscan.bin

Print `HOST:PORT` pairs from the masscan scan file:

    ronin-masscan targets --print-host-ports masscan.bin

Print target hostnames from the masscan scan file:

    ronin-masscan targets --print-hosts --with-port 22 masscan.bin

Print URIs from the masscan scan file:

    ronin-masscan targets --print-uris masscan.bin

## AUTHOR

Postmodern <postmodern.mod3@gmail.com>

