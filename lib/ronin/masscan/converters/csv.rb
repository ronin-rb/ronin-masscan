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

require 'masscan/output_file'
require 'csv'

module Ronin
  module Masscan
    module Converters
      #
      # Handles converting masscan scan files into CSV.
      #
      module CSV
        #
        # Converts the masscan scan file to CSV.
        #
        # @param [::Masscan::OutputFile] masscan_file
        #   The opened masscan scan file.
        #
        # @param [IO, nil] output
        #   Optional output stream to write the CSV to.
        #
        # @return [String]
        #   The raw CSV.
        #
        def self.convert(masscan_file,output=nil)
          masscan_file_to_csv(masscan_file,output)
        end

        #
        # Converts a masscan scan file to CSV.
        #
        # @param [::Masscan::OutputFile] massscan_file
        #   The masscan scan file to convert to CSV.
        #
        # @param [String, IO] output
        #   The optional output to write the CSV to.
        #
        # @return [String, IO]
        #   The CSV output.
        #
        def self.masscan_file_to_csv(masscan_file,output=String.new)
          masscan_file_to_rows(masscan_file) do |row|
            output << ::CSV.generate_line(row)
          end

          return output
        end

        # CSV rows header.
        HEADER = %w[type status.status status.protocol status.port status.reason status.ttl status.ip status.timestamp banner.protocol banner.port banner.ip banner.timestamp banner.app_protocol banner.payload]

        #
        # Converts an opened masscan scan file to a series of rows.
        #
        # @param [::Masscan::OutputFile] masscan_file
        #   The opened masscan scan file.
        #
        # @yield [row]
        #   The given block will be passed each row.
        #
        # @yieldparam [Array] row
        #   A row to be converted to CSV.
        #
        def self.masscan_file_to_rows(masscan_file)
          yield HEADER

          masscan_file.each do |record|
            yield record_to_row(record)
          end
        end

        def self.record_to_row(record)
          case record
          when ::Masscan::Status
            status_record_to_row(record)
          when ::Masscan::Banner
            banner_record_to_row(record)
          else
            raise(NotImplementedError,"unable to convert masscan record: #{record.inspect}")
          end
        end

        def self.status_record_to_row(status)
          ['status', status.status, status.protocol, status.port, status.reason.join(','), status.ttl, status.ip, status.timestamp]
        end

        def self.banner_record_to_row(banner)
          ['banner', nil, nil, nil, nil, nil, nil, nil, banner.protocol, banner.port, banner.ip, banner.timestamp, banner.app_protocol, banner.payload]
        end
      end
    end
  end
end
