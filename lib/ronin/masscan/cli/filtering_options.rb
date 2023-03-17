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

require 'ronin/masscan/cli/port_list'

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
                                    desc: 'Filter the targets by IP range' do |ip_range|
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
        # Filters the masscan targets.
        #
        # @param [::Masscan::OutputFile] output_file
        #   The parsed nmap xml data to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered targets.
        #
        def filter_targets(output_file)
          targets = output_file.each.lazy

          targets = if (!@with_app_protocols.empty? || !@with_payloads.empty?)
                      filter_banner_targets(targets)
                    else
                      filter_status_targets(targets)
                    end

          unless @protocols.empty?
            targets = filter_targets_by_protocol(targets)
          end

          unless @ips.empty?
            targets = filter_targets_by_ip(targets)
          end

          unless @ip_ranges.empty?
            targets = filter_targets_by_ip_range(targets)
          end

          unless @ports.empty?
            targets = filter_targets_by_port(targets)
          end

          unless @with_app_protocols.empty?
            targets = filter_targets_by_app_protocol(targets)
          end

          unless @with_payloads.empty?
            targets = filter_targets_by_payload(targets)
          end

          return targets
        end

        #
        # Filter `Masscan::Status` targets.
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @return [Enumerator::Lazy]
        #   The filtered targets.
        #
        def filter_status_targets(targets)
          targets.filter do |target|
            target.kind_of?(::Masscan::Status)
          end
        end

        #
        # Filter `Masscan::Banner` targets.
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @return [Enumerator::Lazy]
        #   The filtered targets.
        #
        def filter_banner_targets(targets)
          targets.filter do |target|
            target.kind_of?(::Masscan::Banner)
          end
        end

        #
        # Filters the targets by protocol
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered targets.
        #
        def filter_targets_by_protocol(targets)
          targets.filter do |target|
            @protocols.include?(target.protocol)
          end
        end

        #
        # Filters the targets by IP address.
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @param [String] ip
        #   The IP address to filter by.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered targets.
        #
        def filter_targets_by_ip(targets)
          targets.filter do |target|
            @ips.include?(target.ip)
          end
        end

        #
        # Filters the targets by an IP rangeo.
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered targets.
        #
        def filter_targets_by_ip_range(targets)
          targets.filter do |target|
            @ip_ranges.any? do |ip_range|
              ip_range.include?(target.ip)
            end
          end
        end

        #
        # Filters the targets by port number.
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered targets.
        #
        def filter_targets_by_port(targets)
          targets.filter do |target|
            @ports.include?(target.port)
          end
        end

        #
        # Filters the targets by app-protocol IDs.
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered targets.
        #
        def filter_targets_by_app_protocol(targets)
          targets.filter do |banner|
            @with_app_protocols.include?(banner.app_protocol)
          end
        end

        #
        # Filters the targets by payload contents.
        #
        # @param [Enumerator::Lazy] targets
        #   The targets to filter.
        #
        # @return [Enumerator::Lazy]
        #   A lazy enumerator of the filtered targets.
        #
        def filter_targets_by_payload(targets)
          regexp = Regexp.union(@with_payloads.to_a)

          targets.filter do |banner|
            banner.payload =~ regexp
          end
        end
      end
    end
  end
end
