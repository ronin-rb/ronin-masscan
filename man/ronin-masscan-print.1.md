# ronin-masscan-print 1 "2023-03-01" Ronin Masscan "User Manuals"

## NAME

ronin-masscan-print - Prints the scanned IPs and ports from masscan scan file(s)

## SYNOPSIS

`ronin-masscan print` [options] *MASSCAN_FILE*

## DESCRIPTION

Parses one or more masscan scan files and pretty prints the scanned IPs and
open ports. The command also supports filtering the scanned ports by IP,
IP range, domain, or port.

## ARGUMENTS

*MASSCAN_FILE*
: The masscan scan file to import.

## OPTIONS

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

## AUTHOR

Postmodern <postmodern.mod3@gmail.com>

## SEE ALSO

[ronin-masscan-dump](ronin-masscan-dump.1.md)
