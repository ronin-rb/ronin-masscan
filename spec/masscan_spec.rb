require 'spec_helper'
require 'ronin/masscan'

describe Ronin::Masscan do
  let(:fixtures_dir) { File.join(__dir__,'spec','fixtures') }

  describe ".parse" do
    let(:path) { File.join(fixtures_dir,'masscan.json') }

    it "must return a Masscan::OutputFile object for the given path" do
      output_file = subject.parse(path)

      expect(output_file).to be_kind_of(Masscan::OutputFile)
      expect(output_file.path).to eq(path)
    end
  end

  describe '.scan' do
    let(:ips) { '192.168.1.1' }

    context 'when ip adresses are not given' do
      it 'must raise an ArgumentError' do
        expect {
          subject.scan
        }.to raise_error(ArgumentError, 'must specify at least one IP address')
      end
    end

    context 'when masscan command was successful' do
      let(:masscan_command) { Masscan::Command.new(ips: ips, output_file: tempfile.path) }
      let(:tempfile)        { Tempfile.create(['masscan', '.json']) }

      before do
        allow(Masscan::Command).to receive(:new).and_return(masscan_command)
        allow(Kernel).to receive(:system).with({}, 'masscan', '--output-filename', anything, ips).and_return(true)
      end

      it 'must return a Masscan::OutputFile' do
        result = subject.scan(ips, ports: 80)

        expect(result).to be_a(Masscan::OutputFile)
        expect(result.path).to eq(masscan_command.output_file)
      end
    end

    context 'when masscan command fails' do
      before do
        allow(Kernel).to receive(:system).with({}, 'masscan', '--output-filename', anything, ips).and_return(false)
      end

      it 'must return false' do
        expect(subject.scan(ips)).to be(false)
      end
    end

    context 'when masscan command is not installed' do
      before do
        allow(Kernel).to receive(:system).with({}, 'masscan', '--output-filename', anything, ips).and_return(nil)
      end

      it 'must return nil' do
        expect(subject.scan(ips)).to be(nil)
      end
    end
  end
end
