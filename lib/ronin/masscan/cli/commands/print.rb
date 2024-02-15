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
require 'masscan/output_file'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # Prints the scanned IPs and ports from masscan scan file(s).
        #
        # ## Usage
        #
        #     ronin-masscan print [options] MASSCAN_FILE [...]
        #
        # ## Options
        #
        #     -P, --protocol tcp|udp           Filters the targets by protocol
        #         --ip IP                      Filters the targets by IP
        #         --ip-range CIDR              Filter the targets by IP range
        #         -p, --ports {PORT | PORT1-PORT2},...
        #                                      Filter targets by port number
        #         --with-app-protocol APP_PROTOCOL[,...]
        #                                      Filters targets with the app protocol
        #         --with-payload STRING        Filters targets containing the payload
        #         --with-payload-regex /REGEX/ Filters targets with the matching payload
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     MASSCAN_FILE ...                 The masscan scan file(s) to parse
        #
        class Print < Command

          usage '[options] MASSCAN_FILE [...]'

          include FilteringOptions

          argument :masscan_file, required: true,
                                  repeats:  true,
                                  desc:     'The masscan scan file(s) to parse'

          description 'Prints the scanned IPs and ports from masscan scan file(s)'

          man_page 'ronin-masscan-print.1'

          #
          # Runs the `ronin-masscan print` command.
          #
          # @param [Array<String>] masscan_files
          #   The nmap `.xml` files to parse.
          #
          def run(*masscan_files)
            masscan_files.each do |masscan_file|
              output_file = begin
                              ::Masscan::OutputFile.new(masscan_file)
                            rescue ArgumentError => error
                              print_error(error.message)
                              exit(1)
                            end

              records = filter_records(output_file)

              records.group_by(&:ip).each do |ip,records|
                print_records_for(ip,records)
              end
            end
          end

          #
          # Prints the open ports for the IP.
          #
          # @param [String] ip
          #
          # @param [Array<::Masscan::Status, ::Masscan::Banner>] records
          #
          def print_records_for(ip,records)
            puts "[ #{ip} ]"
            puts

            records.each do |record|
              case record
              when ::Masscan::Status
                puts "  #{record.port}/#{record.protocol}\t#{record.status}"
              when ::Masscan::Banner
                puts "    #{record.app_protocol}\t#{record.banner}"
              end
            end
          end

        end
      end
    end
  end
end
