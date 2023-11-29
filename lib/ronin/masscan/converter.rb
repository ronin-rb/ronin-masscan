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
      # @api public
      #
      def self.convert_file(src,dest, format: infer_format_for(dest))
        scan_file = ::Masscan::OutputFile.new(src)
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
      # @param [IO, String, nil] output
      #   Optional output to write the converted output to.
      #
      # @param [:json, :csv] format
      #   The desired convert to convert the parsed masscan scan file to.
      #
      # @return [String]
      #   The converted masscan scan file.
      #
      # @api public
      #
      def self.convert(masscan_file,output=nil, format: )
        Converters[format].convert(masscan_file,output)
      end

      #
      # Infers the output format from the output file's extension.
      #
      # @param [String] output_path
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
