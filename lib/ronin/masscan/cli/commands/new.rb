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

require_relative '../command'
require_relative '../../root'

require 'ronin/core/cli/generator'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # ## Usage
        #
        #     ronin-masscan new [options] FILE
        #
        # ## Options
        #
        #         --parser                     Generate a masscan output file parser script
        #         --scanner                    Generate a masscan scanner script
        #         --printing                   Adds additional printing of the masscan scan data
        #         --import                     Also import the masscan scan data
        #         --output-file OUTPUT_FILE    Sets the output file to write to or parse
        #     -p {PORT | [PORT1]-[PORT2]},..., Sets the port range to scan
        #         --ports
        #         --ips {IP | IP-range}[,..]   Sets the targets to scan (Defaults: ARGV[0])
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     PATH                             The path to the new masscan ruby script
        #
        # ## Examples
        #
        #     ronin-masscan new scanner.rb --ports 22,80,443,8000-9000 --ips '192.168.1.*'
        #     ronin-masscan new parser.rb --parser --output-file path/to/masscan.bin --printing
        #
        class New < Command

          include Core::CLI::Generator

          template_dir File.join(ROOT,'data','templates')

          usage '[options] FILE'

          option :parser, desc: 'Generate a masscan output file parser script' do
            @script_type = :parser
          end

          option :scanner, desc: 'Generate a masscan scanner script' do
            @script_type = :scanner
          end

          option :printing, desc: 'Adds additional printing of the masscan scan data' do
            @features[:printing] = true
          end

          option :import, desc: 'Also import the masscan scan data' do
            @features[:import] = true
          end

          option :output_file, value: {
                                 type:  String,
                                 usage: 'OUTPUT_FILE'
                               },
                               desc: 'Sets the output file to write to or parse' do |file|
                                 @output_file = file
                               end

          option :ports, short: '-p',
                         value: {
                           type:  String,
                           usage: '{PORT | [PORT1]-[PORT2]},...'
                         },
                         desc: 'Sets the port range to scan' do |ports|
                           @ports = parse_port_range(ports)
                         rescue ArgumentError => error
                           raise(OptionParser::InvalidArgument,error.message)
                         end

          option :ips, value: {
                         type:  String,
                         usage: '{IP | IP-range}[,..]'
                       },
                       desc: 'Sets the IPs to scan (Defaults: ARGV)' do |ips|
                         @ips << ips
                       end

          argument :path, desc: 'The path to the new masscan ruby script'

          description 'Generates a new masscan ruby script'

          man_page 'ronin-masscan-new.1'

          examples [
            "scanner.rb --ports 22,80,443,8000-9000 --ips '192.168.1.*'",
            "parser.rb --parser --output-file path/to/masscan.bin --printing"
          ]

          # The script type.
          #
          # @return [:scanner, :parser]
          attr_reader :script_type

          # The optioanl output file to write to or parse.
          #
          # @return [String, nil]
          attr_reader :output_file

          # The optional ports to scan.
          #
          # @return [Array<Integer, Range(Integer,Integer)>, nil]
          attr_reader :ports

          # The IP addresses or ranges to scan.
          #
          # @return [Array<String>]
          attr_reader :ips

          # Additional features.
          #
          # @return [Hash{Symbol => Boolean}]
          attr_reader :features

          #
          # Initializes the `ronin-masscan new` command.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for the command.
          #
          def initialize(**kwargs)
            super(**kwargs)

            @script_type = :scanner
            @ips         = []
            @features    = {}
          end

          #
          # Runs the `ronin-masscan new` command.
          #
          # @param [String] file
          #   The path to the new masscan ruby script.
          #
          def run(file)
            @directory  = File.dirname(file)

            mkdir @directory unless File.directory?(@directory)

            erb "script.rb.erb", file
            chmod '+x', file
          end

          #
          # Parses a port range.
          #
          # @param [String] ports
          #   The port range to parse.
          #
          # @return [Array<Integer, Range(Integer,Integer)>]
          #   The parsed port range.
          #
          # @raise [ArgumentError]
          #   An invalid port range was given.
          #
          def parse_port_range(ports)
            ports.split(',').map do |port|
              case port
              when /\A\d+-\d+\z/
                start, stop = port.split('-',2)

                (start.to_i..stop.to_i)
              when /\A\d+\z/
                port.to_i
              else
                raise(ArgumentError,"invalid port range: #{ports.inspect}")
              end
            end
          end

        end
      end
    end
  end
end
