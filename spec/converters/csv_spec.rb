require 'spec_helper'
require 'ronin/masscan/converters/csv'
require 'tempfile'

RSpec.describe Ronin::Masscan::Converters::CSV do
  let(:fixtures_path) { File.expand_path(File.join(__dir__, '..', 'fixtures')) }
  let(:masscan_path)  { File.join(fixtures_path, 'converters', 'input.json') }
  let(:masscan_file)  { Masscan::OutputFile.new(masscan_path) }

  let(:header_row)    { Ronin::Masscan::Converters::CSV::HEADER }
  let(:header_line)   { CSV.generate_line(header_row) }

  let(:ip)            { '93.184.216.34' }
  let(:ip_addr)       { IPAddr.new(ip) }
  let(:protocol)      { :tcp }
  let(:port)          { 80 }
  let(:ttl)           { 54 }
  let(:timestamp)     { Time.at(1629960621) }

  let(:status_status) { :open }
  let(:status_reason) { [:syn, :ack] }
  let(:expected_status_row) do
    [
      'status',
      status_status,
      protocol,
      port,
      status_reason.join(','),
      ttl,
      ip_addr,
      timestamp
    ]
  end
  let(:expected_status_line) { CSV.generate_line(expected_status_row) }

  let(:banner_app_protocol) { :html_title }
  let(:banner_payload)      { '404 - Not Found' }
  let(:expected_banner_row) do
    [
      'banner',
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      protocol,
      port,
      ip,
      timestamp,
      banner_app_protocol,
      banner_payload
    ]
  end
  let(:expected_banner_line) { CSV.generate_line(expected_banner_row) }

  describe '.convert' do
    it 'must convert masscan file to csv and write it into output' do
      tempfile = Tempfile.new(['ronin-masscan', '.json'])

      subject.convert(masscan_file, tempfile)

      tempfile.rewind
      csv = tempfile.readlines

      expect(csv[0]).to eq(header_line)
      expect(csv[1]).to eq(expected_status_line)
      expect(csv[2]).to eq(expected_banner_line)
    end
  end

  describe '.masscan_file_to_csv' do
    it 'must convert masscan file to csv and write it into output' do
      tempfile = Tempfile.new(['ronin-masscan', '.json'])

      subject.masscan_file_to_csv(masscan_file, tempfile)

      tempfile.rewind
      csv = tempfile.readlines

      expect(csv[0]).to eq(header_line)
      expect(csv[1]).to eq(expected_status_line)
      expect(csv[2]).to eq(expected_banner_line)
    end
  end

  describe '.masscan_file_to_rows' do
    it 'must yields headers and each row from a masscan file' do
      yielded_values = []

      subject.masscan_file_to_rows(masscan_file) do |row|
        yielded_values << row
      end

      expect(yielded_values.size).to eq(3)
      expect(yielded_values[0]).to eq(header_row)
      expect(yielded_values[1]).to eq(expected_status_row)
      expect(yielded_values[2]).to eq(expected_banner_row)
    end
  end

  describe '.record_to_row' do
    context 'for status record' do
      let(:record) do
        Masscan::Status.new(
          ip:        ip_addr,
          protocol:  protocol,
          port:      port,
          reason:    status_reason,
          status:    status_status,
          timestamp: timestamp,
          ttl:       ttl
        )
      end

      it 'must convert it to row' do
        expect(subject.record_to_row(record)).to eq(expected_status_row)
      end
    end

    context 'for banner record' do
      let(:record) do
        Masscan::Banner.new(
          protocol:     protocol,
          port:         port,
          ip:           ip_addr,
          timestamp:    timestamp,
          app_protocol: banner_app_protocol,
          payload:      banner_payload
        )
      end

      it 'must convert it to row' do
        expect(subject.record_to_row(record)).to eq(expected_banner_row)
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
    let(:status) do
      Masscan::Status.new(
        ip:        ip_addr,
        protocol:  protocol,
        port:      port,
        reason:    status_reason,
        status:    status_status,
        timestamp: timestamp,
        ttl:       ttl
      )
    end

    it 'must return row for status' do
      expect(subject.status_record_to_row(status)).to eq(expected_status_row)
    end
  end

  describe '.banner_record_to_row' do
    let(:banner) do
      Masscan::Banner.new(
        protocol:     protocol,
        port:         port,
        ip:           ip_addr,
        timestamp:    timestamp,
        app_protocol: banner_app_protocol,
        payload:      banner_payload
      )
    end

    it 'must return row for banner' do
      expect(subject.banner_record_to_row(banner)).to eq(expected_banner_row)
    end
  end
end
