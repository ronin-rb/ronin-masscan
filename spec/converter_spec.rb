require 'spec_helper'
require 'ronin/masscan/converter'
require 'masscan/output_file'
require 'tempfile'

RSpec.describe Ronin::Masscan::Converter do
  let(:fixtures_path) { File.expand_path(File.join(__dir__, '..', 'spec', 'fixtures')) }
  let(:masscan_path)  { File.join(fixtures_path, 'converters', 'input.json') }
  let(:timestamp)     { JSON.parse(File.read(masscan_path))[0]["timestamp"].to_i }
  let(:masscan_file)  { Masscan::OutputFile.new(masscan_path) }
  let(:json_data) do
    [
      {
        status:    :open,
        protocol:  :tcp,
        port:      80,
        reason:    ['syn', 'ack'],
        ttl:       54,
        ip:        '93.184.216.34',
        timestamp: Time.at(timestamp)
      },
      {
        protocol:     :tcp,
        port:         80,
        ip:           '93.184.216.34',
        timestamp:    Time.at(timestamp),
        app_protocol: 'html_title',
        payload:      '404 - Not Found'
      }
    ]
  end
  let(:expected_json) { json_data.to_json }
  let(:csv_data) do
    [
      [
        "type", "status.status", "status.protocol", "status.port",
        "status.reason", "status.ttl", "status.ip", "status.timestamp",
        "banner.protocol", "banner.port", "banner.ip", "banner.timestamp",
        "banner.app_protocol", "banner.payload"
      ],
      [
        "status", "open", "tcp", "80", "syn,ack", "54", "93.184.216.34", Time.at(timestamp)
      ],
      [
        "banner", nil , nil, nil, nil, nil, nil, nil, "tcp", "80", "93.184.216.34",Time.at(timestamp), "html_title", "404 - Not Found"
      ]
    ]
  end
  let(:expected_csv) do
    CSV.generate do |csv|
      csv_data.each do |row|
        csv << row
      end
    end
  end

  describe '.convert_file' do
    let(:tempfile) { ['dest', '.json'] }

    it 'must convert masscan file and wirte it into a file' do
      Tempfile.create(tempfile) do |output_file|
        subject.convert_file(masscan_path, output_file)
        output_file.rewind

        expect(output_file.read).to eq(expected_json)
      end
    end

    context 'when format is given' do
      it 'must ignore file extension and convert it to the given format' do
        Tempfile.create(tempfile) do |output_file|
          subject.convert_file(masscan_path, output_file, format: :csv)
          output_file.rewind

          expect(output_file.read).to eq(expected_csv)
        end
      end
    end

    context 'when input_format and format are given' do
      it 'must set input file format explicitly and convert it to the given format' do
        Tempfile.create(tempfile) do |output_file|
          subject.convert_file(masscan_path, output_file, input_format: :json, format: :csv)
          output_file.rewind

          expect(output_file.read).to eq(expected_csv)
        end
      end
    end
  end

  describe '.convert' do
    context 'when there is no output' do
      context 'and format is csv' do
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
