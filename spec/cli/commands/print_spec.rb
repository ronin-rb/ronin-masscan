require 'spec_helper'
require 'ronin/masscan/cli/commands/print'
require_relative 'man_page_example'

describe Ronin::Masscan::CLI::Commands::Print do
  include_examples "man_page"

  describe "#run"

  describe "#print_open_ports"
end
