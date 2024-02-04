require 'spec_helper'
require 'ronin/masscan/converters/csv'
require 'tempfile'

RSpec.describe Ronin::Masscan::Converters::CSV do
  let(:fixtures_path) { File.expand_path(File.join(__dir__, '..', 'fixtures')) }
  let(:masscan_path)  { File.join(fixtures_path, 'masscan_files', 'two_records.json') }
  let(:masscan_file)  { Masscan::OutputFile.new(masscan_path) }
  let(:ip_addr)       { IPAddr.new('93.184.216.34/32') }
  let(:timestamp)     { 1629960621 }
  let(:header)        { Ronin::Masscan::Converters::CSV::HEADER }

  describe '.convert' do
    let(:expected_status_row) { "status,open,tcp,80,\"syn,ack\",54,93.184.216.34,#{Time.at(timestamp)}" }
    let(:expected_banner_row) { "banner,,,,,,,,tcp,80,93.184.216.34,#{Time.at(timestamp)},html_title,404 - Not Found" }

    it 'must convert masscan file to csv and write it into output' do
      Tempfile.create do |output_file|
        subject.convert(masscan_file, output_file)
        output_file.rewind

        result = 3.times.map { output_file.gets(chomp: true) }

        expect(result[0]).to eq(header.join(','))
        expect(result[1]).to eq(expected_status_row)
        expect(result[2]).to eq(expected_banner_row)
      end
    end
  end

  describe '.masscan_file_to_csv' do
    let(:expected_status_row) { "status,open,tcp,80,\"syn,ack\",54,93.184.216.34,#{Time.at(timestamp)}" }
    let(:expected_banner_row) { "banner,,,,,,,,tcp,80,93.184.216.34,#{Time.at(timestamp)},html_title,404 - Not Found" }

    it 'must convert masscan file to csv and write it into output' do
      Tempfile.create do |output_file|
        subject.masscan_file_to_csv(masscan_file, output_file)
        output_file.rewind

        result = 3.times.map { output_file.gets(chomp: true) }

        expect(result[0]).to eq(header.join(','))
        expect(result[1]).to eq(expected_status_row)
        expect(result[2]).to eq(expected_banner_row)
      end
    end
  end

  describe '.masscan_file_to_rows' do
    let(:expected_status_row) do
      ['status', :open, :tcp, 80, "syn,ack", 54, ip_addr, Time.at(timestamp)]
    end
    let(:expected_banner_row) do
      ["banner", nil, nil, nil, nil, nil, nil, nil, :tcp, 80, ip_addr, Time.at(timestamp), :html_title, '404 - Not Found']
    end

    it 'must yields headers and each row from a masscan file' do
      yielded_values = []

      subject.masscan_file_to_rows(masscan_file) do |row|
        yielded_values << row
      end

      expect(yielded_values.size).to eq(3)
      expect(yielded_values[0]).to eq(Ronin::Masscan::Converters::CSV::HEADER)
      expect(yielded_values[1]).to eq(expected_status_row)
      expect(yielded_values[2]).to eq(expected_banner_row)
    end
  end

  describe '.record_to_row' do
    context 'for status record' do
      let(:record) {
        Masscan::Status.new(
          ip: ip_addr,
          protocol: :tcp,
          port: 80,
          reason: [:syn, :ack],
          status: :open,
          timestamp: Time.at(1629960621),
          ttl: 54
        )
      }
      let(:expected_row) do
        ['status', :open, :tcp, 80, "syn,ack", 54, ip_addr, Time.at(timestamp)]
      end

      it 'must convert it to row' do
        expect(subject.record_to_row(record)).to eq(expected_row)
      end
    end

    context 'for banner record' do
      let(:record) {
        Masscan::Banner.new(
          protocol: :icmp,
          port: 80,
          ip: ip_addr,
          timestamp: 1629960621,
          app_protocol: :html_title,
          payload: '404 - Not Found'
        )
      }
      let(:expected_row) do
        ['banner', nil, nil, nil, nil, nil, nil, nil, :icmp, 80, ip_addr, timestamp, :html_title, '404 - Not Found']
      end

      it 'must convert it to row' do
        expect(subject.record_to_row(record)).to eq(expected_row)
      end
    end

    context 'for unknown record' do
      let(:record) { 'unknown' }

      it 'must raise a NotImplementedError' do
        expect {
          subject.record_to_row(record)
        }.to raise_error(NotImplementedError, "unable to convert masscan record: #{record.inspect}")
      end
    end
  end

  describe '.status_record_to_row' do
    let(:status) {
      Masscan::Status.new(
        ip: ip_addr,
        protocol: :tcp,
        port: 80,
        reason: [:syn, :ack],
        status: :open,
        timestamp: Time.at(1629960621),
        ttl: 54
      )
    }
    let(:expected_row) do
      ['status', :open, :tcp, 80, "syn,ack", 54, ip_addr, Time.at(timestamp)]
    end

    it 'must return row for status' do
      expect(subject.status_record_to_row(status)).to eq(expected_row)
    end
  end

  describe '.banner_record_to_row' do
    let(:banner) {
      Masscan::Banner.new(
        protocol: :icmp,
        port: 80,
        ip: ip_addr,
        timestamp: 1629960621,
        app_protocol: :html_title,
        payload: '404 - Not Found'
      )
    }
    let(:expected_row) do
      ['banner', nil, nil, nil, nil, nil, nil, nil, :icmp, 80, ip_addr, timestamp, :html_title, '404 - Not Found']
    end

    it 'must return row for banner' do
      expect(subject.banner_record_to_row(banner)).to eq(expected_row)
    end
  end
end
