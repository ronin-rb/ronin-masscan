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

module Ronin
  module Masscan
    #
    # Base class for all {Ronin::Masscan} exceptions.
    #
    # @api public
    #
    class Exception < RuntimeError
    end

    #
    # Indicates that the `masscan` command is not installed.
    #
    # @api public
    #
    class NotInstalled < Exception
    end

    #
    # Indicates that the `masscan` scan failed.
    #
    # @api public
    #
    class ScanFailed < Exception
    end
  end
end