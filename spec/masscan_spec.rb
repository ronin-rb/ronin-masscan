require 'spec_helper'
require 'ronin/masscan'

describe Ronin::Masscan do
  let(:fixtures_dir) { File.join(__dir__,'fixtures') }

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

    let(:expected_output_filename) { %r{#{Ronin::Masscan::CACHE_DIR}\/masscan[^.]+\.json} }

    context 'when IPs are given as arguments' do
      it 'must pass the IPs to the `masscan` command' do
        expect(Kernel).to receive(:system).with({}, 'masscan', '-p', '80', '--output-filename', match(expected_output_filename), ips).and_return(true)

        subject.scan(ips, ports: 80)
      end
    end

    context "when IPs are not given as arguments" do
      context "but a block is given" do
        context "and the IPs are set in the block" do
          it 'must pass the IPs to the `masscan` command' do
            expect(Kernel).to receive(:system).with({}, 'masscan', '-p', '80', '--output-filename', match(expected_output_filename), ips).and_return(true)

            subject.scan do |masscan|
              masscan.ports = 80
              masscan.ips   = ips
            end
          end
        end
      end
    end

    context 'when masscan command was successful' do
      before do
        allow(Kernel).to receive(:system).with({}, 'masscan', '-p', '80', '--output-filename', match(expected_output_filename), ips).and_return(true)
      end

      it 'must return a Masscan::OutputFile' do
        expect(subject.scan(ips, ports: 80)).to be_a(Masscan::OutputFile)
      end
    end

    context 'when masscan command fails' do
      before do
        allow(Kernel).to receive(:system).with({}, 'masscan', '--output-filename', anything, ips).and_return(false)
      end

      it "must raise Ronin::Masscan::ScanFailed with the command arguments" do
        expect {
          subject.scan(ips)
        }.to raise_error(Ronin::Masscan::ScanFailed,/\Amasscan scan failed: masscan --output-filename [^\s]+ [^\s]+\z/)
      end
    end

    context 'when masscan command is not installed' do
      before do
        allow(Kernel).to receive(:system).with({}, 'masscan', '--output-filename', anything, ips).and_return(nil)
      end

      it "must raise Ronin::Masscan::NotInstalled" do
        expect {
          subject.scan(ips)
        }.to raise_error(Ronin::Masscan::NotInstalled,"the masscan command is not installed")
      end
    end
  end
end
