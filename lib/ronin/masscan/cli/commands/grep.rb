# frozen_string_literal: true
#
# ronin-masscan - A Ruby library and CLI for working with masscan.
#
# Copyright (c) 2023-2024 Hal Brodigan (postmodern.mod3@gmail.com)
#
# ronin-masscan is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ronin-masscan is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ronin-masscan.  If not, see <https://www.gnu.org/licenses/>.
#

require 'ronin/masscan/cli/command'
require 'ronin/masscan/cli/filtering_options'

require 'command_kit/colors'
require 'command_kit/printing/indent'
require 'masscan/output_file'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # Greps the scanned services from masscan scan file(s) for the given
        # pattern.
        #
        # ## Usage
        #
        #     ronin-masscan grep [options] PATTERN MASSCAN_FILE [...]
        #
        # ## Options
        #
        #     -P, --protocol tcp|udp           Filters the targets by protocol
        #         --ip IP                      Filters the targets by IP
        #         --ip-range CIDR              Filters the targets by IP range
        #         -p, --ports {PORT | PORT1-PORT2},...
        #                                      Filters targets by port number
        #         --with-app-protocol APP_PROTOCOL[,...]
        #                                      Filters targets with the app protocol
        #         --with-payload STRING        Filters targets containing the payload
        #         --with-payload-regex /REGEX/ Filters targets with the matching payload
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     PATTERN                          The pattern to search for
        #     MASSCAN_FILE ...                 The masscan scan file(s) to parse
        #
        class Grep < Command

          usage '[options] PATTERN MASSCAN_FILE [...]'

          include CommandKit::Colors
          include CommandKit::Printing::Indent
          include FilteringOptions

          argument :pattern, required: true,
                             desc:     'The pattern to search for'

          argument :masscan_file, required: true,
                                  repeats:  true,
                                  desc:     'The masscan scan file(s) to parse'

          description 'Greps the scanned services from masscan scan file(s)'

          man_page 'ronin-masscan-grep.1'

          #
          # Runs the `ronin-masscan grep` command.
          #
          # @param [String] pattern
          #   The pattern to search for.
          #
          # @param [Array<String>] masscan_files
          #   The nmap `.xml` files to parse.
          #
          def run(pattern,*masscan_files)
            masscan_files.each do |masscan_file|
              unless File.file?(masscan_file)
                print_error "no such file or directory: #{masscan_file}"
                next
              end

              output_file = begin
                              ::Masscan::OutputFile.new(masscan_file)
                            rescue ArgumentError => error
                              print_error(error.message)
                              exit(1)
                            end

              records = grep_records(output_file,pattern)

              highlight_records(records,pattern)
            end
          end

          #
          # Greps the masscan output file for the pattern.
          #
          # @param [::Masscan::OutputFile] output_file
          #   The masscan output file to search.
          #
          # @param [String] pattern
          #   The pattern to search for.
          #
          def grep_records(output_file,pattern)
            records = filter_records(output_file)

            records.filter { |record| match_record(record,pattern) }
          end

          #
          # Determines if the masscan record includes the pattern.
          #
          # @param [::Masscan::Status, ::Masscan::Banner] record
          #   The masscan record to search.
          #
          # @param [String] pattern
          #   The pattern to search for.
          #
          # @return [Boolean]
          #   Indicates whether the masscan record contains the pattern.
          #
          def match_record(record,pattern)
            case record
            when ::Masscan::Banner
              record.app_protocol.match(pattern) ||
                record.payload.match(pattern)
            end
          end

          #
          # Prints the open ports for the IP.
          #
          # @param [Array<::Masscan::Status, ::Masscan::Banner>] records
          #   The masscan records to print.
          #
          # @param [String] pattern
          #   The pattern to highlight.
          #
          def highlight_records(records,pattern)
            records.group_by(&:ip).each do |ip,records_for_ip|
              puts "[ #{ip} ]"
              puts

              records_for_ip.group_by { |record|
                [record.port, record.protocol]
              }.each do |(port,protocol),records_for_port|
                indent do
                  puts "#{port}/#{protocol}"

                  indent do
                    records_for_port.each do |record|
                      highlight_record(record,pattern)
                    end
                  end
                end
              end

              puts
            end
          end

          #
          # Prints the masscan record with the pattern highlighted.
          #
          # @param [::Masscan:Status, ::Masscan::Banner] record
          #   The masscan record to print.
          #
          # @param [String] pattern
          #   The pattern to highlight.
          #
          def highlight_record(record,pattern)
            case record
            when ::Masscan::Banner
              highlight_banner_record(record,pattern)
            end
          end

          #
          # Prints the masscan banner record with the pattern highlighted.
          #
          # @param [::Masscan::Banner] banner
          #   The masscan banner record to print.
          #
          # @param [String] pattern
          #   The pattern to highlight.
          #
          def highlight_banner_record(banner,pattern)
            payload      = highlight(banner.payload,pattern)
            app_protocol = highlight(banner.app_protocol,pattern)

            if payload.include?("\n") # multiline?
              puts app_protocol

              indent do
                payload.chomp.each_line(chomp: true) do |line|
                  puts line
                end
              end
            else
              puts "#{app_protocol}\t#{payload}"
            end
          end

          #
          # Highlights the pattern in the text.
          #
          # @param [String] text
          #   The text to modify.
          #
          # @param [String] pattern
          #   The pattern to highlight.
          #
          # @return [String]
          #   The modified text.
          #
          def highlight(text,pattern)
            text.to_s.gsub(pattern,colors.red(pattern))
          end

        end
      end
    end
  end
end
