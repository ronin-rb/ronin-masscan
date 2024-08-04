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

require_relative 'port_list'

module Ronin
  module Masscan
    class CLI
      #
      # Mixin which adds nmap target filtering options to commands.
      #
      module FilteringOptions
        #
        # Adds filtering options to the command class including
        # {FilteringOptions}.
        #
        # @param [Class<Command>] command
        #   The command class including {FilteringOptions}.
        #
        def self.included(command)
          command.option :protocol, short: '-P',
                                    value: {
                                      type: [:tcp, :udp]
                                    },
                                    desc: 'Filters the targets by protocol' do |proto|
                                      @protocols << proto
                                    end

          command.option :ip, value: {
                                type:  String,
                                usage: 'IP'
                              },
                              desc: 'Filters the targets by IP' do |ip|
                                @ips << ip
                              end

          command.option :ip_range, value: {
                                      type:  String,
                                      usage: 'CIDR'
                                    },
                                    desc: 'Filters the targets by IP range' do |ip_range|
                                      @ip_ranges << IPAddr.new(ip_range)
                                    end

          command.option :ports, short: '-p',
                                 value: {
                                   type: /\A(?:\d+|\d+-\d+)(?:,(?:\d+|\d+-\d+))*\z/,
                                   usage: '{PORT | PORT1-PORT2},...'
                                 },
                                 desc: 'Filter targets by port number' do |ports|
                                   @ports << PortList.parse(ports)
                                 end

          command.option :with_app_protocol, value: {
                                               type:  /\A[a-z][a-z0-9_-]*\z/,
                                               usage: 'APP_PROTOCOL[,...]'
                                             },
                                             desc: 'Filters targets with the app protocol' do |app_protocol|
                                               @with_app_protocols << app_protocol.to_sym
                                             end

          command.option :with_payload, value: {
                                          type:  String,
                                          usage: 'STRING'
                                        },
                                        desc: 'Filters targets containing the payload' do |string|
                                          @with_payloads << string
                                        end

          command.option :with_payload_regex, value: {
                                                type:  Regexp,
                                                usage: '/REGEX/'
                                              },
                                              desc: 'Filters targets with the matching payload' do |regexp|
                                                @with_payloads << regexp
                                              end
        end

        # The protocols to filter the targets by.
        #
        # @return [Set<:tcp, :udp>]
        attr_reader :protocols

        # The IPs to filter the targets by.
        #
        # @return [Set<String>]
        attr_reader :ips

        # The IP ranges to filter the targets by.
        #
        # @return [Set<IPAddr>]
        attr_reader :ip_ranges

        # The ports to filter the targets by.
        #
        # @return [Set<PortList>]
        attr_reader :ports

        # The app protocols to filter the targets by.
        #
        # @return [Set<String>]
        attr_reader :with_app_protocols

        # The payload Strings or Regexps to filter the targets by.
        #
        # @return [Set<String, Regexp>]
        attr_reader :with_payloads

        #
        # Initializes the command.
        #
        # @param [Hash{Symbol => String}] kwargs
        #   Additional keywords for the command.
        #
        def initialize(**kwargs)
          super(**kwargs)

          @protocols = Set.new
          @ips       = Set.new
          @ip_ranges = Set.new
          @ports     = Set.new

          # Masscan::Banner filtering options
          @with_app_protocols = Set.new
          @with_payloads      = Set.new
        end

        #
        # Filters the masscan records.
        #
        # @param [::Masscan::OutputFile] output_file
        #   The parsed nmap xml data to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered records.
        #
        def filter_records(output_file)
          records = output_file.each.lazy

          unless @protocols.empty?
            records = filter_records_by_protocol(records)
          end

          unless @ips.empty?
            records = filter_records_by_ip(records)
          end

          unless @ip_ranges.empty?
            records = filter_records_by_ip_range(records)
          end

          unless @ports.empty?
            records = filter_records_by_port(records)
          end

          unless @with_app_protocols.empty?
            records = filter_records_by_app_protocol(records)
          end

          unless @with_payloads.empty?
            records = filter_records_by_payload(records)
          end

          return records
        end

        #
        # Filter `Masscan::Status` records.
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   The filtered records.
        #
        def filter_status_records(records)
          records.filter do |record|
            record.kind_of?(::Masscan::Status)
          end
        end

        #
        # Filter `Masscan::Banner` records.
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   The filtered records.
        #
        def filter_banner_records(records)
          records.filter do |record|
            record.kind_of?(::Masscan::Banner)
          end
        end

        #
        # Filters the records by protocol
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered records.
        #
        def filter_records_by_protocol(records)
          records.filter do |record|
            @protocols.include?(record.protocol)
          end
        end

        #
        # Filters the records by IP address.
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered records.
        #
        def filter_records_by_ip(records)
          records.filter do |record|
            @ips.include?(record.ip)
          end
        end

        #
        # Filters the records by an IP rangeo.
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered records.
        #
        def filter_records_by_ip_range(records)
          records.filter do |record|
            @ip_ranges.any? do |ip_range|
              ip_range.include?(record.ip)
            end
          end
        end

        #
        # Filters the records by port number.
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered records.
        #
        def filter_records_by_port(records)
          records.filter do |record|
            @ports.include?(record.port)
          end
        end

        #
        # Filters the records by app-protocol IDs.
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered records.
        #
        def filter_records_by_app_protocol(records)
          records.filter do |record|
            record.kind_of?(::Masscan::Banner) &&
              @with_app_protocols.include?(record.app_protocol)
          end
        end

        #
        # Filters the records by payload contents.
        #
        # @param [Enumerator::Lazy] records
        #   The records to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered records.
        #
        def filter_records_by_payload(records)
          regexp = Regexp.union(@with_payloads.to_a)

          records.filter do |record|
            record.kind_of?(::Masscan::Banner) &&
              record.payload =~ regexp
          end
        end
      end
    end
  end
end
