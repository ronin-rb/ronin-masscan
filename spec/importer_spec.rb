require 'spec_helper'
require 'ronin/masscan/importer'
require 'masscan/output_file'
require 'ronin/db'

RSpec.describe Ronin::Masscan::Importer do
  let(:output_file) { instance_double('Masscan::OutputFile') }

  describe '.import_file' do
    let(:path) { '/path/to/file' }

    before do
      allow(Masscan::OutputFile).to receive(:new).with(path).and_return(output_file)
    end

    it 'must initialize Masscan::OutputFile and import from it' do
      expect(subject).to receive(:import).with(output_file)

      subject.import_file(path)
    end
  end

  describe '.import' do
    let(:status_record)  { Masscan::Status.new(protocol: :tcp, port: 80, ip: "1.1.1.1", status: "status", timestamp: Time.now) }
    let(:banner_record)  { instance_double("Masscan::Banner") }
    let(:unknown_record) { 'unknown_record' }

    before do
      allow(output_file).to receive(:each).and_yield(unknown_record)
      allow(subject).to receive(:import_status)
    end

    it 'raises NotImplementedError for unknown record types' do
      expect { |b|
        subject.import(output_file, &b)
      }.to raise_error(NotImplementedError)
    end

    context 'when a block is given' do
      before do
        allow(output_file).to receive(:each).and_yield(status_record)
      end

      it 'must import status' do
        expect(subject).to receive(:import_status)

        subject.import(output_file) { |f| f }
      end
    end

    context 'when no block is given' do
      it 'must return an enumerator' do
        expect(subject).to receive(:enum_for)

        subject.import(output_file)
      end
    end
  end

  describe '.import_status' do
    let(:status) { instance_double('Masscan::Status') }
    let(:ip)     { "1.1.1.1" }

    context 'when Masscan::Status status is :open' do
      context 'when Masscan::Status protocol is :icmp' do
        before do
          allow(status).to receive(:status).and_return(:open)
          allow(status).to receive(:protocol).and_return(:icmp)
          allow(status).to receive(:ip).and_return(ip)
        end

        it 'must import ip address' do
          expect(subject).to receive(:import_ip_address).with(ip)

          subject.import_status(status)
        end
      end

      context 'when Masscan::Status protocol is not :icmp' do
        before do
          allow(status).to receive(:status).and_return(:open)
          allow(status).to receive(:protocol).and_return(:not_icmp)
        end

        it 'must import open port status' do
          expect(subject).to receive(:import_open_port_status).with(status)

          subject.import_status(status)
        end
      end
    end
  end

  describe '.import_open_port_status' do
    let(:status)    { instance_double('Masscan::Status', ip: '1.1.1.1', port: 80, protocol: :tcp, timestamp: Time.now) }
    let(:ip_addr)   { instance_double('Ronin::DB::IpAddress') }
    let(:port)      { instance_double('Ronin::DB::Port') }
    let(:open_port) { instance_double('Ronin::DB::OpenPort') }

    before do
      Ronin::DB.connect
      allow(subject).to receive(:import_ip_address).and_return(ip_addr)
      allow(subject).to receive(:import_port).and_return(port)
      allow(open_port).to receive(:update)
      allow(Ronin::DB::OpenPort).to receive(:find_or_create_by).and_return(open_port)
    end

    context 'when block is given' do
      it 'must yield open and return port' do
        expect { |b|
          subject.import_open_port_status(status, &b)
        }.to yield_with_args(open_port)
      end
    end

    it 'must return open port' do
      expect(subject.import_open_port_status(status)).to eq(open_port)
    end
  end

  describe '.import_ip_address' do
    let(:ipv4_address)        { IPAddr.new('192.168.1.1') }
    let(:ipv6_address)        { IPAddr.new('2001:0db8:85a3:0000:0000:8a2e:0370:7334') }
    let(:imported_ip_address) { instance_double("Ronin::DB::IPAddress") }

    before do
      Ronin::DB.connect
      allow(Ronin::DB::IPAddress).to receive(:find_or_create_by).and_return(imported_ip_address)
    end

    it 'imports an IPv4 address' do
      expect(Ronin::DB::IPAddress).to receive(:find_or_create_by).with(version: 4, address: ipv4_address.to_s)

      subject.import_ip_address(ipv4_address)
    end

    it 'imports an IPv6 address' do
      expect(Ronin::DB::IPAddress).to receive(:find_or_create_by).with(version: 6, address: ipv6_address.to_s)

      subject.import_ip_address(ipv6_address)
    end

    context 'when a block is given' do
      it 'yields the imported IP address' do
        expect { |b|
          subject.import_ip_address(ipv4_address, &b)
        }.to yield_with_args(imported_ip_address)
      end
    end

    it 'returns the imported IP address' do
      expect(subject.import_ip_address(ipv4_address)).to eq(imported_ip_address)
    end
  end

  describe '.import_port' do
    let(:port_number) { 80 }
    let(:protocol)    { :tcp }
    let(:port)        { instance_double('Ronin::DB::Port') }

    before do
      Ronin::DB.connect
      allow(Ronin::DB::Port).to receive(:find_or_create_by).with(protocol: protocol, number: port_number).and_return(port)
    end

    context 'when block if given' do
      it 'must yeild imported port' do
        expect { |b|
          subject.import_port(port_number, protocol, &b)
        }.to yield_with_args(port)
      end
    end

    it 'must return imported port' do
      expect(subject.import_port(port_number, protocol)).to eq(port)
    end
  end
end
