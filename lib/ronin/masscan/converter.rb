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

require 'ronin/masscan/converters'

require 'masscan/output_file'

module Ronin
  module Masscan
    #
    # Handles converting masscan scan file into other formats.
    #
    # Supports the following formats:
    #
    # * JSON
    # * CSV
    #
    # @api public
    #
    module Converter
      # Mapping of file extension names to formats.
      #
      # @api private
      FILE_FORMATS = {
        '.json' => :json,
        '.csv'  => :csv
      }

      #
      # Converts an masscan scan file into another format.
      #
      # @param [String] src
      #   The input masscan scan file path.
      #
      # @param [String] dest
      #   The output file path.
      #
      # @param [:binary, :list, :json, :ndjson, nil] input_format
      #   The explicit format of the input masscan scan file.
      #   If not specified the input format will be inferred from the file's
      #   extension.
      #
      # @param [:json, :csv] format
      #   The format to convert the masscan scan file into. If not specified
      #   it will be inferred from the output file's extension.
      #
      # @api public
      #
      def self.convert_file(src,dest, input_format: nil,
                                      format:       infer_format_for(dest))
        scan_file = if input_format
                      ::Masscan::OutputFile.new(src, format: input_format)
                    else
                      ::Masscan::OutputFile.new(src)
                    end

        converter = Converters[format]

        File.open(dest,'w') do |output|
          converter.convert(scan_file,output)
        end
      end

      #
      # Converts parsed masscan scan file into the desired format.
      #
      # @param [::Masscan::OutputFile] masscan_file
      #   The masscan scan file to convert.
      #
      # @param [IO, nil] output
      #   Optional output to write the converted output to.
      #
      # @param [:json, :csv] format
      #   The desired convert to convert the parsed masscan scan file to.
      #
      # @return [IO, String]
      #   The converted masscan scan file.
      #
      # @api public
      #
      def self.convert(masscan_file,output=nil, format: )
        if output
          Converters[format].convert(masscan_file,output)
        else
          output = StringIO.new
          convert(masscan_file,output, format:)
          output.string
        end
      end

      #
      # Infers the output format from the output file's extension.
      #
      # @param [String] path
      #   The output file name.
      #
      # @return [:json, :csv]
      #   The conversion format.
      #
      # @raise [ArgumentError]
      #   The format could not be inferred from the path's file extension.
      #
      # @api private
      #
      def self.infer_format_for(path)
        FILE_FORMATS.fetch(File.extname(path)) do
          raise(ArgumentError,"cannot infer output format from path: #{path.inspect}")
        end
      end
    end
  end
end
