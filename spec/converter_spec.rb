require 'spec_helper'
require 'ronin/masscan/converter'
require 'masscan/output_file'
require 'tempfile'

RSpec.describe Ronin::Masscan::Converter do
  let(:fixtures_path) { File.expand_path(File.join(__dir__, '..', 'spec', 'fixtures')) }
  let(:masscan_path)  { File.join(fixtures_path, 'converter', 'masscan.json') }
  let(:masscan_file)  { Masscan::OutputFile.new(masscan_path) }
  let(:expected_json) do
    "[{\"status\":\"open\",\"protocol\":\"tcp\",\"port\":80,\"reason\":[\"syn\",\"ack\"],\"ttl\":54,\"ip\":\"93.184.216.34\",\"timestamp\":\"2021-08-26 08:50:21 +0200\"}]"
  end

  describe '.convert_file' do
    it 'must convert masscan file and wirte it into a file' do
      Tempfile.create(['dest', '.json']) do |output_file|
        subject.convert_file(masscan_path, output_file)
        output_file.rewind

        expect(output_file.read).to eq(expected_json)
      end
    end
  end

  describe '.convert' do
    context 'when there is no output' do
      context 'and format is csv' do
        let(:expected_csv) do
          "type,status.status,status.protocol,status.port,status.reason,status.ttl,status.ip,status.timestamp,banner.protocol,banner.port,banner.ip,banner.timestamp,banner.app_protocol,banner.payload\nstatus,open,tcp,80,\"syn,ack\",54,93.184.216.34,2021-08-26 08:50:21 +0200\n"
        end

        it 'must convert masscan file into csv' do
          expect(subject.convert(masscan_file, format: :csv)).to eq(expected_csv)
        end
      end

      context 'and format is json' do
        it 'must convert masscan file into json' do
          expect(subject.convert(masscan_file, format: :json)).to eq(expected_json)
        end
      end
    end

    context 'when there is an output' do
      it 'must write converted output into it' do
        Tempfile.create('masscan.json') do |output_file|
          subject.convert(masscan_file, output_file, format: :json)
          output_file.rewind
        
          expect(output_file.read).to eq(expected_json)
        end
      end
    end
  end

  describe '.infer_format_for' do
    context 'for json file' do
      let(:path) { 'path/with/valid_extension.json' }

      it 'must return correct format' do
        expect(subject.infer_format_for(path)).to eq(:json)
      end
    end

    context 'for csv file' do
      let(:path) { 'path/with/valid_extension.csv' }

      it 'must return correct format' do
        expect(subject.infer_format_for(path)).to eq(:csv)
      end
    end

    context 'for file with unknown extension' do
      let(:path) { '/path/with/invalid_extension.txt' }

      it 'must raise an ArgumentError' do
        expect {
          subject.infer_format_for(path)
        }.to raise_error(ArgumentError, "cannot infer output format from path: #{path.inspect}")
      end
    end
  end
end