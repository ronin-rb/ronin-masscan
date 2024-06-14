# ronin-masscan 1 "2024-01-01" Ronin Masscan "User Manuals"

## NAME

ronin-masscan - A CLI for working with masscan

## SYNOPSIS

`ronin-masscan` [*options*] [*COMMAND* [...]]

## DESCRIPTION

`ronin-masscan` provides various commands for automating `masscan`, parsing
scan output files, and importing scan data into the database.

## ARGUMENTS

*COMMAND*
: The `ronin-masscan` command to execute.

## OPTIONS

`-h`, `--help`
: Print help information

## COMMANDS

*completion*
: Manages the shell completion rules for `ronin-masscan`.

*convert*
: Converts an masscan scan file to JSON or CSV.

*dump*
: Dumps the scanned ports from masscan scan files.

*import*
: Imports a masscan scan file into ronin-db.

*new*
: Generates a new masscan Ruby script.

*scan*
: Runs masscan and outputs data as JSON or CSV or imports into the database.

## AUTHOR

Postmodern <postmodern.mod3@gmail.com>

## SEE ALSO

[ronin-masscan-completion](ronin-masscan-completion.1.md) [ronin-masscan-convert](ronin-masscan-convert.1.md) [ronin-masscan-dump](ronin-masscan-dump.1.md) [ronin-masscan-import](ronin-masscan-import.1.md) [ronin-masscan-new](ronin-masscan-new.1.md) [ronin-masscan-scan](ronin-masscan-scan.1.md)
