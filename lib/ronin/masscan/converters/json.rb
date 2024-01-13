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

require 'masscan/output_file'
require 'json'

module Ronin
  module Masscan
    module Converters
      #
      # Handles converting masscan scan files into JSON.
      #
      module JSON
        #
        # Converts the masscan scan file to JSON.
        #
        # @param [::Masscan::OutputFile] masscan_file
        #   The opened masscan scan file.
        #
        # @param [IO, nil] output
        #   Optional output stream to write the JSON to.
        #
        # @return [String]
        #   The raw JSON.
        #
        def self.convert(masscan_file,output=nil)
          masscan_file_to_json(masscan_file,output)
        end

        #
        # Converts the masscan scan file to JSON.
        #
        # @param [::Masscan::OutputFile] masscan_file
        #   The opened masscan scan file.
        #
        # @param [IO, nil] output
        #   Optional output stream to write the JSON to.
        #
        # @return [String]
        #   The raw JSON.
        #
        def self.masscan_file_to_json(masscan_file,output=nil)
          ::JSON.dump(masscan_file_as_json(masscan_file),output)
        end

        #
        # Converts a masscan scan file into JSON representation.
        #
        # @param [::Masscan::OutputFile] output_file
        #   The opened masscan file.
        #
        # @return [Array<Hash{Symbol => Object}>]
        #   The JSON representation of the masscan scan file.
        #
        def self.masscan_file_as_json(output_file)
          output_file.each.map do |record|
            record_as_json(record)
          end
        end

        #
        # Converts a masscan record into a JSON representation.
        #
        # @param [::Masscan::Status, ::Masscan::Banner] record
        #   The masscan status or banner record to convert.
        #
        # @return [Hash{Symbol => Object}]
        #   The JSON representation of the record.
        #
        def self.record_as_json(record)
          case record
          when ::Masscan::Status
            status_as_json(record)
          when ::Masscan::Banner
            banner_as_json(record)
          else
            raise(NotImplementedError,"unable to convert masscan record: #{record.inspect}")
          end
        end

        #
        # Converts a masscan status record into a JSON representation.
        #
        # @param [::Masscan::Status] status
        #   The masscan status record to convert.
        #
        # @return [Hash{Symbol => Object}]
        #   The JSON representation of the record.
        #
        def self.status_as_json(status)
          hash = {
            status:    status.status,
            protocol:  status.protocol,
            port:      status.port,
            reason:    status.reason,
            ttl:       status.ttl,
            ip:        status.ip,
            timestamp: status.timestamp
          }

          # omit the `mac` field if it's nil
          hash[:mac] = status.mac if status.mac

          return hash
        end

        #
        # Converts a masscan record into a JSON representation.
        #
        # @param [::Masscan::Banner] banner
        #   The masscan banner record to convert.
        #
        # @return [Hash{Symbol => Object}]
        #   The JSON representation of the record.
        #
        def self.banner_as_json(banner)
          {
            protocol:     banner.protocol,
            port:         banner.port,
            ip:           banner.ip,
            timestamp:    banner.timestamp,
            app_protocol: banner.app_protocol,
            payload:      banner.payload
          }
        end
      end
    end
  end
end
