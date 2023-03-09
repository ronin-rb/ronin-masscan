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
require 'ronin/masscan/converter'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # Converts an masscan scan file to JSON or CSV.
        #
        # ## Usage
        #
        #     ronin-masscan convert [--format json|csv] MASSCAN_FILE [OUTPUT_FILE]
        #
        # ## Option
        #
        #     -F, --format json|csv            The desired output format
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     MASSCAN_FILE                     The input masscan scan file to parse
        #     OUTPUT_FILE                      The output file
        #
        class Convert < Command

          usage '[--format json|csv] MASSCAN_FILE [OUTPUT_FILE]'

          option :format, short: '-F',
                          value: {
                            type:     [:json, :csv],
                            required: true
                          },
                          desc: 'The desired output format'

          argument :masscan_file, required: true,
                                  desc:     'The input masscan scan file to convert'

          argument :output_file, required: false,
                                 desc:     'The output file'

          description "Converts an masscan scan file to JSON or CSV"

          man_page 'ronin-masscan-convert.1'

          # The desired output format.
          #
          # @return [:json, :csv, nil]
          attr_reader :format

          #
          # Runs the `ronin-masscan convert` command.
          #
          # @param [String] masscan_file
          #   The XML input file to parse.
          #
          # @param [String] output_file
          #   The output file to write to.
          #
          def run(masscan_file,output_file=nil)
            unless File.file?(masscan_file)
              print_error "no such file or directory: #{masscan_file}"
              exit(-1)
            end

            if output_file
              if (format = options[:format])
                Converter.convert_file(masscan_file,output_file, format: format)
              else
                Converter.convert_file(masscan_file,output_file)
              end
            else
              unless (format = options[:format])
                print_error "must specify a --format if no output file is given"
                exit(-1)
              end

              masscan_file = ::Masscan::OutputFile.new(masscan_file)

              Converter.convert(masscan_file,stdout, format: format)
            end
          end

        end
      end
    end
  end
end
