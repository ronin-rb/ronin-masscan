# ronin-masscan-convert 1 "2023-03-01" Ronin "User Manuals"

## SYNOPSIS

`ronin-masscan convert` [`--format` `json`\|`csv`] *MASSCAN_FILE* [*OUTPUT_FILE*]

## DESCRIPTION

Converts an masscan scan file to JSON or CSV.

## ARGUMENTS

*MASSCAN_FILE*
  The masscan scan file to import.

*OUTPUT_FILE*
  The optional output file to write to.

## OPTIONS

`-F`, `--format` `json`|`csv`
  Sets the output conversion format to JSON or CSV. If the option is not given,
  the output conversion format Will be inferred from the *OUTPUT_FILE* file
  extension.

`-h`, `--help`
  Print help information

## AUTHOR

Postmodern <postmodern.mod3@gmail.com>

