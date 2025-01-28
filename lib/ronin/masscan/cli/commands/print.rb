# frozen_string_literal: true
#
# ronin-masscan - A Ruby library and CLI for working with masscan.
#
# Copyright (c) 2023-2025 Hal Brodigan (postmodern.mod3@gmail.com)
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

require_relative '../command'
require_relative '../filtering_options'

require 'masscan/output_file'
require 'command_kit/printing/indent'

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
        #         --ip-range CIDR              Filters the targets by IP range
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

          include CommandKit::Printing::Indent
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

              print_records(records)
            end
          end

          #
          # Prints the open ports for the IP.
          #
          # @param [Array<::Masscan::Status, ::Masscan::Banner>] records
          #
          def print_records(records)
            records.group_by(&:ip).each do |ip,records_for_ip|
              puts "[ #{ip} ]"
              puts

              records_for_ip.group_by { |record|
                [record.port, record.protocol]
              }.each_value do |records_for_port|
                status  = records_for_port.first
                banners = records_for_port[1..]

                indent do
                  print_status_record(status)

                  unless banners.empty?
                    indent do
                      banners.each do |banner|
                        print_banner_record(banner)
                      end
                    end

                    puts
                  end
                end
              end
            end
          end

          #
          # Prints a masscan status record.
          #
          # @param [::Masscan::Status] status
          #   The status record that indicates whether a port is open or not.
          #
          def print_status_record(status)
            puts "#{status.port}/#{status.protocol}\t#{status.status}"
          end

          #
          # Prints a masscan banner record.
          #
          # @param [::Masscan::Banner] banner
          #   The banner record that contains additional information about the
          #   port's service.
          #
          def print_banner_record(banner)
            payload      = banner.payload
            app_protocol = banner.app_protocol

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

        end
      end
    end
  end
end
