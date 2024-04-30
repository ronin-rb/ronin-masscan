require 'spec_helper'
require 'ronin/masscan/cli/commands/dump'
require_relative 'man_page_example'

require 'stringio'

RSpec.describe Ronin::Masscan::CLI::Commands::Dump do
  include_examples "man_page"

  let(:stdout) { StringIO.new }

  subject { described_class.new(stdout: stdout) }

  let(:fixtures_dir) { File.expand_path(File.join(__dir__,'..','..','fixtures')) }
  let(:masscan_path) { File.join(fixtures_dir, 'masscan.json') }
  let(:output_file)  { Masscan::OutputFile.new(masscan_path) }
  let(:records)      { output_file.each.to_a }
  let(:status)       { records[0] }
  let(:banner)       { records[-1] }

  describe '#run' do
    let(:result) do
      <<~OUTPUT
        93.184.216.34:80
        93.184.216.34:443
        93.184.216.34:0
        93.184.216.34:80
        93.184.216.34:80
        93.184.216.34:80
        93.184.216.34:443
        93.184.216.34:443
      OUTPUT
    end

    it 'must print target for all masscan banners and statuses in the file' do
      subject.run(masscan_path)

      expect(stdout.string).to eq(result)
    end
  end

  describe '#print_target' do
    context 'for :ips mode' do
      before { subject.option_parser.parse('--print-ips') }

      it 'must print a ip' do
        subject.print_target(status)

        expect(stdout.string).to eq("93.184.216.34#{$/}")
      end
    end

    context 'for :ip_ports mode' do
      before { subject.option_parser.parse('--print-ip-ports') }

      it 'must print a ip:port pair' do
        subject.print_target(status)

        expect(stdout.string).to eq("93.184.216.34:80#{$/}")
      end
    end

    context 'for :uris mode' do
      before { subject.option_parser.parse('--print-uris') }

      it 'must print an uri' do
        subject.print_target(status)

        expect(stdout.string).to eq("http://93.184.216.34#{$/}")
      end
    end
  end

  describe '#print_ip' do
    context 'for Masscan::Status' do
      it 'must print ip' do
        subject.print_ip(status)

        expect(stdout.string).to eq("93.184.216.34#{$/}")
      end
    end

    context 'for Masscan::Banner' do
      it 'must print ip' do
        subject.print_ip(banner)

        expect(stdout.string).to eq("93.184.216.34#{$/}")
      end
    end
  end

  describe '#print_ip_ports' do
    context 'for Masscan::Status' do
      it 'must print ip:port pair' do
        subject.print_ip_ports(status)

        expect(stdout.string).to eq("93.184.216.34:80#{$/}")
      end
    end

    context 'for Masscan::Banner' do
      it 'must print ip:port pair' do
        subject.print_ip_ports(banner)

        expect(stdout.string).to eq("93.184.216.34:443#{$/}")
      end
    end
  end

  describe '#print_uri' do
    context 'for Masscan::Status' do
      it 'must prints URI' do
        subject.print_uri(status)

        expect(stdout.string).to eq("http://93.184.216.34#{$/}")
      end
    end

    context 'for Masscan::Banner' do
      it 'must prints URI' do
        subject.print_uri(banner)

        expect(stdout.string).to eq("https://93.184.216.34#{$/}")
      end
    end
  end
end
