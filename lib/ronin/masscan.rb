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

require_relative 'masscan/exceptions'
require_relative 'masscan/importer'

require 'ronin/core/home'
require 'masscan/command'
require 'masscan/output_file'

require 'tempfile'
require 'fileutils'

module Ronin
  #
  # Top-level methods for `ronin-masscan`.
  #
  module Masscan
    # The `~/.cache/ronin-masscan` cache directory.
    #
    # @api private
    CACHE_DIR = Core::Home.cache_dir('ronin-masscan')

    #
    # Runs `masscan` and parses the saved output data.
    #
    # @param [Array<#to_s>] ips
    #   The IP addresses to scan.
    #
    # @param [Hash{Symbol => Object}] kwargs
    #   Additional keyword arguments for `masscan`.
    #
    # @return [::Masscan::OutputFile]
    #   If the `masscan` command was sucessful, the parsed masscan data will be
    #   returned.
    #
    # @raise [NotInstalled]
    #   The `masscan` command is not installed.
    #
    # @raise [ScanFailed]
    #   The `masscan` scan failed.
    #
    # @see https://rubydoc.info/gems/ruby-masscan/Masscan/OutputFile
    #
    # @api public
    #
    def self.scan(*ips,**kwargs,&block)
      masscan = ::Masscan::Command.new(ips: ips, **kwargs,&block)

      masscan.ips ||= ips

      unless masscan.output_file
        FileUtils.mkdir_p(CACHE_DIR)
        tempfile = Tempfile.new(['masscan', '.json'], CACHE_DIR)

        masscan.output_file = tempfile.path
      end

      status = masscan.run_command

      case status
      when nil
        raise(NotInstalled,"the masscan command is not installed")
      when false
        raise(ScanFailed,"masscan scan failed: #{masscan.command_argv.join(' ')}")
      else
        parse(masscan.output_file)
      end
    end

    #
    # Parses a masscan output file.
    #
    # @param [String] path
    #   The path to the output file.
    #
    # @param [Hash{Symbol => Object}] kwargs
    #   Additional keyword arguments for `::Masscan::OutputFile.new`.
    #
    # @option kwargs [:binary, :list, :json, :ndjson] :format
    #   The format of the output file. If not specified, the format will be
    #   inferred from the path's file extension.
    #
    # @return [::Masscan::OutputFile]
    #   The parsed masscan output file.
    #
    # @raise [ArgumentError]
    #   The output format was not given and it cannot be inferred.
    #
    # @see https://rubydoc.info/gems/ruby-masscan/Masscan/OutputFile
    #
    # @api public
    #
    def self.parse(path,**kwargs)
      ::Masscan::OutputFile.new(path,**kwargs)
    end
  end
end
