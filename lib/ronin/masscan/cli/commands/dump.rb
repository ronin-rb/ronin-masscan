# frozen_string_literal: true
#
# ronin-masscan - A Ruby library and CLI for working with masscan.
#
# Copyright (c) 2023-2026 Hal Brodigan (postmodern.mod3@gmail.com)
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
require 'set'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # Dumps the scanned ports from masscan scan file(s).
        #
        # ## Usage
        #
        #     ronin-masscan dump [options] MASSCAN_FILE [...]
        #
        # ## Options
        #
        #         --print-ips                  Print all IP addresses
        #         --print-hosts                Print all hostnames
        #         --print-ip-ports             Print IP:PORT pairs. (Default)
        #         --print-host-ports           Print HOST:PORT pairs
        #         --print-uris                 Print URIs
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
        # ## Examples
        #
        #     ronin-masscan dump --print-ip-ports masscan.bin
        #     ronin-masscan dump --print-ip-ports --ports 22,80,443 masscan.bin
        #     ronin-masscan dump --print-host-ports masscan.bin
        #     ronin-masscan dump --print-hosts --with-port 22 masscan.bin
        #     ronin-masscan dump --print-uris masscan.bin
        #
        class Dump < Command

          usage '[options] MASSCAN_FILE [...]'

          option :print_ips, desc: 'Print all IP addresses' do
            @mode = :ips
          end

          option :print_hosts, desc: 'Print all hostnames' do
            @mode = :hostnames
          end

          option :print_ip_ports, desc: 'Print IP:PORT pairs. (Default)' do
            @mode = :ip_ports
          end

          option :print_host_ports, desc: 'Print HOST:PORT pairs' do
            @mode = :host_ports
          end

          option :print_uris, desc: 'Print URIs' do
            @mode = :uris
          end

          include FilteringOptions

          argument :masscan_file, required: true,
                                  repeats:  true,
                                  desc:     'The masscan scan file(s) to parse'

          examples [
            '--print-ip-ports masscan.bin',
            '--print-ip-ports --ports 22,80,443 masscan.bin',
            '--print-host-ports masscan.bin',
            '--print-hosts --with-port 22 masscan.bin',
            '--print-uris masscan.bin'
          ]

          description 'Dumps the scanned ports from masscan scan file(s)'

          man_page 'ronin-masscan-dump.1'

          #
          # Initializes the command.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keywords for the command.
          #
          def initialize(**kwargs)
            super(**kwargs)

            @mode = :ip_ports
          end

          #
          # Runs the `ronin-masscan dump` command.
          #
          # @param [Array<String>] masscan_files
          #   The masscan scan file(s) to parse.
          #
          def run(*masscan_files)
            masscan_files.each do |masscan_file|
              output_file = begin
                              ::Masscan::OutputFile.new(masscan_file)
                            rescue ArgumentError => error
                              print_error(error.message)
                              exit(1)
                            end

              filter_records(output_file).each do |target|
                print_target(target)
              end
            end
          end

          #
          # Prints the target.
          #
          # @param [::Masscan::Status, ::Masscan::Banner] host
          #
          def print_target(host)
            case @mode
            when :ips      then print_ip(host)
            when :ip_ports then print_ip_ports(host)
            when :uris     then print_uri(host)
            end
          end

          #
          # Prints the IPs for the target.
          #
          # @param [::Masscan::Status, ::Masscan::Banner] target
          #
          def print_ip(target)
            puts target.ip
          end

          #
          # Prints the `IP:PORT` pair for the target.
          #
          # @param [::Masscan::Status, ::Masscan::Banner] target
          #
          def print_ip_ports(target)
            puts "#{target.ip}:#{target.port}"
          end

          #
          # Prints the URIs for the target.
          #
          # @param [::Masscan::Status, ::Masscan::Banner] target
          #
          def print_uri(target)
            case target.port
            when 80
              puts URI::HTTP.build(
                host: target.ip.to_s,
                port: target.port
              )
            when 443
              puts URI::HTTPS.build(
                host: target.ip.to_s,
                port: target.port
              )
            end
          end

        end
      end
    end
  end
end
