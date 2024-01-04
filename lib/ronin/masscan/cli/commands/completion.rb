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

require 'ronin/masscan/root'
require 'ronin/core/cli/completion_command'

module Ronin
  module Masscan
    class CLI
      module Commands
        #
        # Manages the shell completion rules for `ronin-masscan`.
        #
        # ## Usage
        #
        #     ronin-masscan completion [options]
        #
        # ## Options
        #
        #         --print                      Prints the shell completion file
        #         --install                    Installs the shell completion file
        #         --uninstall                  Uninstalls the shell completion file
        #     -h, --help                       Print help information
        #
        # ## Examples
        #
        #     ronin-masscan completion --print
        #     ronin-masscan completion --install
        #     ronin-masscan completion --uninstall
        #
        class Completion < Core::CLI::CompletionCommand

          completion_file File.join(ROOT,'data','completions','ronin-masscan')

          man_dir File.join(ROOT,'man')
          man_page 'ronin-masscan-completion.1'

          description 'Manages the shell completion rules for ronin-masscan'

        end
      end
    end
  end
end
