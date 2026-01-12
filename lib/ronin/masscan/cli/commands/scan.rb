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
require_relative '../importable'
require_relative '../../converter'

require 'ronin/core/cli/logging'
require 'tempfile'
require 'set'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # Runs masscan and outputs data as JSON or CSV or imports into the
        # database.
        #
        # ## Usage
        #
        #     ronin-masscan scan [options] -- [masscan_options]
        #
        # ## Options
        #
        #         --db NAME                    The database to connect to (Default: default)
        #         --db-uri URI                 The database URI to connect to
        #         --sudo                       Runs the masscan command under sudo
        #     -o, --output FILE                The output file
        #     -F, --output-format json|csv     The output format
        #         --import                     Imports the scan results into the database
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     masscan_options ...              Additional arguments for masscan
        #
        # ## Examples
        #
        #     ronin-masscan scan -o scan.json -- 192.168.1.1
        #     ronin-masscan scan --import -- 192.168.1.1
        #
        class Scan < Command

          include Importable
          include Core::CLI::Logging

          usage '[options] -- [masscan_options]'

          option :sudo, desc: 'Runs the masscan command under sudo'

          option :output, short: '-o',
                          value: {
                            type:  String,
                            usage: 'FILE'
                          },
                          desc: 'The output file'

          option :output_format, short: '-F',
                                 value: {
                                   type: [:json, :csv]
                                 },
                                 desc: 'The output format'

          option :import, desc: 'Imports the scan results into the database'

          argument :masscan_args, required: true,
                               repeats:  true,
                               usage:    'masscan_options',
                               desc:     'Additional arguments for masscan'

          description 'Runs masscan and outputs data as JSON or CSV or imports into the database'

          examples [
            '-o scan.json -- 192.168.1.1',
            '--import -- 192.168.1.1'
          ]

          man_page 'ronin-masscan-scan.1'

          #
          # Runs the `ronin-masscan scan` command.
          #
          # @param [Array<String>] masscan_args
          def run(*masscan_args)
            if (output = options[:output])
              output_format = options.fetch(:output_format) do
                                infer_output_format(output)
                              end

              if output_format.nil?
                print_error "cannot infer the output format of the output file (#{output.inspect}), please specify --output-format"
                exit(1)
              end
            end

            tempfile = Tempfile.new(['ronin-masscan', '.bin'])

            log_info "Running masscan #{masscan_args.join(' ')} ..."

            unless run_masscan(*masscan_args, output: tempfile.path)
              print_error "failed to run masscan"
              exit(1)
            end

            if output
              log_info "Saving #{output_format.upcase} output to #{output} ..."
              save_output(tempfile.path,output, format: output_format)
            end

            if options[:import]
              log_info "Importing masscan output ..."
              import_scan(tempfile.path)
            end
          end

          #
          # Runs the `masscan` command.
          #
          # @param [Array<String>] masscan_args
          #   Additional arguments for `masscan`.
          #
          # @param [String] output
          #   The output file to save the scan data to.
          #
          # @return [Boolean, nil]
          #   Indicates whether the `masscan` command was successful.
          #
          def run_masscan(*masscan_args, output: )
            masscan_command = ['masscan', '-v', *masscan_args, '-oB', output]
            masscan_command.unshift('sudo') if options[:sudo]

            return system(*masscan_command)
          end

          #
          # Saves the masscan scan results to an output file in the given
          # format.
          #
          # @param [String] path
          #   The path to the masscan output file.
          #
          # @param [String] output
          #   The path to the desired output file.
          #
          # @param [:json, :csv] format
          #   The desired output format.
          #
          def save_output(path,output, format: )
            # the format has been explicitly specified
            Converter.convert_file(path,output, format: format)
          end

          #
          # Imports a masscan output file.
          #
          # @param [String] path
          #   The path to the output file.
          #
          def import_scan(path)
            db_connect
            import_file(path)
          end

          # Supported output formats.
          OUTPUT_FORMATS = {
            '.json' => :json,
            '.csv'  => :csv
          }

          #
          # Infers the output format from the given path's file extension.
          #
          # @param [String] path
          #   The path to infer the output format from.
          #
          # @return [:json, :csv, nil]
          #   The output format or `nil` if the path's file extension is
          #   unknown.
          #
          def infer_output_format(path)
            OUTPUT_FORMATS[File.extname(path)]
          end

        end
      end
    end
  end
end
