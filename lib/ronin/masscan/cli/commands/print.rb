# frozen_string_literal: true
#
# ronin-masscan - A Ruby library and CLI for working with masscan.
#
# Copyright (c) 2023 Hal Brodigan (postmodern.mod3@gmail.com)
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

              targets = filter_targets(output_file)

              targets.group_by(&:ip).each do |ip,open_ports|
                print_open_ports(ip,open_ports)
              end
            end
          end

          #
          # Prints the open ports for the IP.
          #
          # @param [String] ip
          #
          # @param [Array<::Masscan::Status, ::Masscan::Banner>] open_ports
          #
          def print_open_ports(ip,open_ports)
            puts "[ #{ip} ]"
            puts

            open_ports.each do |open_port|
              case open_port
              when ::Masscan::Status
                puts "  #{open_port.port}/#{open_port.protocol}\t#{open_port.status}"
              when ::Masscan::Banner
                puts "    #{open_port.app_protocol}\t#{open_port.banner}"
              end
            end
          end

        end
      end
    end
  end
end
