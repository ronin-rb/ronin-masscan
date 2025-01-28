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
require_relative '../../converter'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # Converts an masscan scan file to JSON or CSV.
        #
        # ## Usage
        #
        #     ronin-masscan convert [options] INPUT_FILE [OUTPUT_FILE]
        #
        # ## Option
        #
        #     -I binary|list|json|ndjson,      The input format
        #         --input-format
        #     -F, --format json|csv            The desired output format
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     INPUT_FILE                       The input masscan scan file to parse
        #     OUTPUT_FILE                      The output file
        #
        class Convert < Command

          usage '[options] MASSCAN_FILE [OUTPUT_FILE]'

          option :input_format, short: '-I',
                                value: {
                                  type: [:binary, :list, :json, :ndjson]
                                },
                                desc: 'The input format'

          option :format, short: '-F',
                          value: {
                            type:     [:json, :csv],
                            required: true
                          },
                          desc: 'The desired output format'

          argument :input_file, required: true,
                                desc:     'The input masscan scan file to convert'

          argument :output_file, required: false,
                                 desc:     'The output file'

          description "Converts an masscan scan file to JSON or CSV"

          man_page 'ronin-masscan-convert.1'

          #
          # Runs the `ronin-masscan convert` command.
          #
          # @param [String] input_file
          #   The masscan scan file to parse.
          #
          # @param [String] output_file
          #   The output file to write to.
          #
          def run(input_file,output_file=nil)
            unless File.file?(input_file)
              print_error "no such file or directory: #{input_file}"
              exit(-1)
            end

            masscan_file = open_masscan_file(input_file)

            if output_file
              format = options.fetch(:format) do
                         Converter.infer_format_for(output_file)
                       end

              File.open(output_file,'w') do |output|
                Converter.convert(masscan_file,output, format: format)
              end
            else
              unless (format = options[:format])
                print_error "must specify a --format if no output file is given"
                exit(-1)
              end

              Converter.convert(masscan_file,stdout, format: format)
            end
          end

          #
          # Opens a masscan scan file.
          #
          # @param [String] path
          #   The path to the masscan scan file.
          #
          # @return [::Masscan::OutputFile]
          #   The opened masscan scan file.
          #
          def open_masscan_file(path)
            if options[:input_format]
              ::Masscan::OutputFile.new(path, format: options[:input_format])
            else
              ::Masscan::OutputFile.new(path)
            end
          rescue ArgumentError => error
            print_error(error.message)
            exit(1)
          end

        end
      end
    end
  end
end
