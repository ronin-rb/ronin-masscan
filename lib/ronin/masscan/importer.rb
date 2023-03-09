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

require 'ronin/db'
require 'masscan/output_file'

module Ronin
  module Masscan
    #
    # Handles importing masscan output files file into [ronin-db].
    #
    # [ronin-db]: https://github.com/ronin-rb/ronin-db#readme
    #
    # ## Examples
    #
    #     require 'ronin/db'
    #     require 'ronin/masscan/importer'
    #
    #     Ronin::DB.connect
    #     Ronin::Masscan::Importer.import_file('masscan.scan') do |record|
    #       puts "Imported #{record.inspect}!"
    #     end
    #
    # @api private
    #
    module Importer
      #
      # Imports a masscan output file into the database.
      #
      # @param [String] path
      #   The path to the masscan output file.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for `Masscan::OutputFile#initialize`.
      #
      # @option kwargs [:binary, :list, :json, :ndjson] :format
      #   The format of the output file. If not given, the format will be
      #   inferred from the file extension.
      #
      # @yield [imported]
      #   The given block will be passed each imported database record.
      #
      # @yieldparam [Ronin::DB::IPAddress, Ronin::DB::Port, Ronin::DB::OpenPort] imported
      #
      # @raise [ArgumentError]
      #   The output format was not given and it cannot be inferred.
      #
      def self.import_file(path,**kwargs,&block)
        output_file = ::Masscan::OutputFile.new(path,**kwargs)

        import(output_file,&block)
      end

      #
      # Imports the masscan output file.
      #
      # @param [::Masscan::OutputFile] output_file
      #
      # @yield [imported]
      #   The given block will be passed each imported database record.
      #
      # @yieldparam [Ronin::DB::IPAddress, Ronin::DB::Port, Ronin::DB::OpenPort] imported
      #
      def self.import(output_file,&block)
        return enum_for(__method__,output_file).to_a unless block

        output_file.each do |record|
          case record
          when ::Masscan::Status
            import_status(record,&block)
          when ::Masscan::Banner
            # TODO: somehow import the banner data
          else
            raise(NotImplementedError,"unable to import masscan record: #{record.inspect}")
          end
        end
      end

      #
      # Imports a `Masscan::Status` record into the database.
      #
      # @param [::Masscan::Status] status
      #   The `Masscan::Status` record.
      #
      # @yield [imported]
      #   The given block will be passed each imported database record.
      #
      # @yieldparam [Ronin::DB::IPAddress, Ronin::DB::Port, Ronin::DB::OpenPort] imported
      #   An imported IP address, port number, or open port record.
      #
      # @return [Ronin::DB::OpenPort, Ronin::DB::IPAddress, nil]
      #   The imported open port, or an IP address if the status was an ICMP
      #   probe, or `nil` if the status did not represent an open port.
      #
      def self.import_status(status,&block)
        # only import open ports
        if status.status == :open
          if status.protocol == :icmp
            # only import the IP address for ICMP statuses
            import_ip_address(status.ip,&block)
          else
            import_open_port_status(status,&block)
          end
        end
      end

      #
      # Imports an open port `Masscan::Status` record into the database.
      #
      # @param [::Masscan::Status] status
      #   The `Masscan::Status` record.
      #
      # @yield [imported]
      #   The given block will be passed each imported database record.
      #
      # @yieldparam [Ronin::DB::IPAddress, Ronin::DB::Port, Ronin::DB::OpenPort] imported
      #   An imported IP address, port number, or open port record.
      #
      # @return [Ronin::DB::OpenPort]
      #   The imported open port.
      #
      def self.import_open_port_status(status,&block)
        imported_ip_address = import_ip_address(status.ip,&block)
        imported_port       = import_port(status.port,status.protocol,&block)
        imported_open_port  = DB::OpenPort.transaction do
                                DB::OpenPort.find_or_create_by(
                                  ip_address: imported_ip_address,
                                  port:       imported_port
                                )
                              end

        imported_open_port.update(last_scanned_at: status.timestamp)

        yield imported_open_port if block_given?
        return imported_open_port
      end

      #
      # Imports an IP address into the database.
      #
      # @param [IPAddr] ip_addr
      #   The IP address object to import.
      #
      # @yield [imported]
      #   The given block will be passed the imported IP address record.
      #
      # @yieldparam [Ronin::DB::IPAddress] imported
      #   The imported IP address record.
      #
      # @return [Ronin::DB::IPAddress]
      #   The imported IP address record.
      #
      def self.import_ip_address(ip_addr,&block)
        ip_version = if ip_addr.ipv6? then 6
                     else                  4
                     end

        imported_ip_address = DB::IPAddress.transaction do
                                DB::IPAddress.find_or_create_by(
                                  version: ip_version,
                                  address: ip_addr.to_s
                                )
                              end

        yield imported_ip_address if block_given?
        return imported_ip_address
      end

      #
      # Imports the port.
      #
      # @param [Integer] port
      #   The port number to import.
      #
      # @param [:tcp, :udp] protocol
      #   The protocol of the port.
      #
      # @yield [imported]
      #   The given block will be passed the imported port record.
      #
      # @yieldparam [Ronin::DB::Port] imported
      #   The imported port record.
      #
      # @return [Ronin::DB::Port]
      #   The imported port record.
      #
      def self.import_port(port,protocol,&block)
        imported_port = DB::Port.transaction do
                          DB::Port.find_or_create_by(
                            protocol: protocol,
                            number:   port
                          )
                        end

        yield imported_port if block_given?
        return imported_port
      end
    end
  end
end
