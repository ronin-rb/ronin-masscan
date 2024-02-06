require 'spec_helper'
require 'ronin/masscan/converters/json'
require 'tempfile'

RSpec.describe Ronin::Masscan::Converters::JSON do
  let(:fixtures_path) { File.expand_path(File.join(__dir__, '..', 'fixtures')) }
  let(:masscan_path)  { File.join(fixtures_path, 'converters', 'input.json') }
  let(:masscan_file)  { Masscan::OutputFile.new(masscan_path) }
  let(:ip_addr)       { IPAddr.new('93.184.216.34/32') }
  let(:timestamp)     { Time.at(1629960621) }
  let(:expected_status) do
    {
      status: :open,
      protocol: :tcp,
      port: 80,
      reason: [:syn, :ack],
      ttl: 54,
      ip: ip_addr,
      timestamp: timestamp
    }
  end
  let(:expected_banner) do
    {
      protocol: :tcp,
      port: 80,
      ip: ip_addr,
      timestamp: timestamp,
      app_protocol: :html_title,
      payload: '404 - Not Found'
    }
  end

  describe '.convert' do
    let(:expected_result) { JSON.dump([expected_status, expected_banner]) }

    it 'must convert masscan file to json and write it into an output' do
      tempfile = Tempfile.new(['ronin-masscan', '.json'])

      subject.convert(masscan_file, tempfile)

      tempfile.rewind
      json = tempfile.read
      expect(json).to eq(expected_result)
    end
  end

  describe '.masscan_file_to_json' do
    let(:expected_result) { JSON.dump([expected_status, expected_banner]) }

    it 'must convert masscan file to json and write it into an output' do
      tempfile = Tempfile.new(['ronin-masscan', '.json'])

      subject.convert(masscan_file, tempfile)

      tempfile.rewind
      json = tempfile.read
      expect(json).to eq(expected_result)
    end
  end

  describe '.masscan_file_as_json' do
    let(:expected_result) { [expected_status, expected_banner] }

    it 'must convert masscan file to json representation' do
      expect(subject.masscan_file_as_json(masscan_file)).to eq(expected_result)
    end
  end

  describe '.record_as_json' do
    context 'for Masscan::Status' do
      let(:record) do
        Masscan::Status.new(
          ip: ip_addr,
          protocol: :tcp,
          port: 80,
          reason: [:syn, :ack],
          status: :open,
          timestamp: Time.at(1629960621),
          ttl: 54
        )
      end

      it 'must return status as json' do
        expect(subject.record_as_json(record)).to eq(expected_status)
      end
    end

    context 'for Masscan::Banner' do
      let(:record) do
        Masscan::Banner.new(
          protocol: :tcp,
          port: 80,
          ip: ip_addr,
          timestamp: timestamp,
          app_protocol: :html_title,
          payload: '404 - Not Found'
        )
      end

      it 'must return banner as json' do
        expect(subject.record_as_json(record)).to eq(expected_banner)
      end
    end

    context 'for unknown record' do
      let(:record) { 'unknown' }

      it 'must raise a NotImplementedError' do
        expect {
          subject.record_as_json(record)
        }.to raise_error(NotImplementedError, "unable to convert masscan record: #{record.inspect}")
      end
    end
  end

  describe '.status_as_json' do
    let(:status) do
      Masscan::Status.new(
        ip: ip_addr,
        protocol: :tcp,
        port: 80,
        reason: [:syn, :ack],
        status: :open,
        timestamp: Time.at(1629960621),
        ttl: 54
      )
    end

    it 'must convert Masscan::Status to a Hash' do
      expect(subject.status_as_json(status)).to eq(expected_status)
    end
  end

  describe '.banner_as_json' do
    let(:banner) do
      Masscan::Banner.new(
        protocol: :tcp,
        port: 80,
        ip: ip_addr,
        timestamp: timestamp,
        app_protocol: :html_title,
        payload: '404 - Not Found'
      )
    end

    it 'must convert Masscan::Banner to a Hash' do
      expect(subject.banner_as_json(banner)).to eq(expected_banner)
    end
  end
end
