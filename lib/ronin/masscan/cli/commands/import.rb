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

require 'ronin/masscan/cli/command'
require 'ronin/masscan/cli/importable'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # The `ronin-masscan import` command.
        #
        # ## Usage
        #
        #   ronin-masscan import [options] MASSCAN_FILE
        #
        # ## Options
        #
        #         --db NAME                    The database to connect to (Default: default)
        #         --db-uri URI                 The database URI to connect to
        #     -F binary|list|json|ndjson,      Specifies the format of the scan file
        #         --format
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     MASSCAN_FILE                     The masscan scan file to import
        #
        class Import < Command

          include Importable

          usage '[options] MASSCAN_FILE'

          option :format, short: '-F',
                          value: {
                            type: ::Masscan::OutputFile::PARSERS.keys
                          },
                          desc: 'Specifies the format of the scan file'

          argument :masscan_file, required: true,
                                  desc:     'The masscan scan file to import'

          description 'Imports a masscan scan file into ronin-db'

          man_page 'ronin-masscan-import.1'

          #
          # Runs the `ronin-masscan import` command.
          #
          # @param [String] masscan_file
          #   The masscan scan file to import.
          #
          def run(masscan_file)
            unless File.file?(masscan_file)
              print_error "no such file or directory: #{masscan_file}"
              exit(1)
            end

            require 'ronin/db'
            require 'ronin/masscan/importer'

            DB.connect

            if options[:format]
              import_file(masscan_file, format: options[:format])
            else
              import_file(masscan_file)
            end
          end

        end
      end
    end
  end
end
