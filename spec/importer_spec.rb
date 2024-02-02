require 'spec_helper'
require 'ronin/masscan/importer'
require 'masscan/output_file'
require 'ronin/db'

RSpec.describe Ronin::Masscan::Importer do
  let(:fixtures_dir) { File.expand_path(File.join(__dir__, '..', 'spec', 'fixtures')) }
  let(:masscan_path) { File.join(fixtures_dir, 'masscan.json') }
  let(:output_file)  { Masscan::OutputFile.new(masscan_path) }

  before(:all) do
    Ronin::DB.connect('sqlite3::memory:')
  end

  after(:all) do
    Ronin::DB::OpenPort.destroy_all
    Ronin::DB::IPAddress.destroy_all
    Ronin::DB::Port.destroy_all
  end

  describe '.import_file' do
    it 'must import records from file' do
      yielded_values = []

      subject.import_file(masscan_path) do |value|
        yielded_values << value
      end

      expect(yielded_values.size).to eq(7)
      expect(yielded_values[0]).to be_a(Ronin::DB::IPAddress)
      expect(yielded_values[1]).to be_a(Ronin::DB::Port)
      expect(yielded_values[2]).to be_a(Ronin::DB::OpenPort)
      expect(yielded_values[3]).to be_a(Ronin::DB::IPAddress)
      expect(yielded_values[4]).to be_a(Ronin::DB::Port)
      expect(yielded_values[5]).to be_a(Ronin::DB::OpenPort)
      expect(yielded_values[6]).to be_a(Ronin::DB::IPAddress)
    end
  end

  describe '.import' do
    context 'when an unknown record type is encountered' do
      before do
        allow(output_file).to receive(:each).and_yield("unknown")
      end

      it 'must raise NotImplementedError' do
        expect { |b|
          subject.import(output_file, &b)
        }.to raise_error(NotImplementedError)
      end
    end

    context 'when a block is given' do
      it 'must yield imported records' do
        yielded_values = []

        subject.import(output_file) do |value|
          yielded_values << value
        end

        expect(yielded_values.size).to eq(7)
        expect(yielded_values[0]).to be_a(Ronin::DB::IPAddress)
        expect(yielded_values[1]).to be_a(Ronin::DB::Port)
        expect(yielded_values[2]).to be_a(Ronin::DB::OpenPort)
        expect(yielded_values[3]).to be_a(Ronin::DB::IPAddress)
        expect(yielded_values[4]).to be_a(Ronin::DB::Port)
        expect(yielded_values[5]).to be_a(Ronin::DB::OpenPort)
        expect(yielded_values[6]).to be_a(Ronin::DB::IPAddress)
      end
    end

    context 'when no block is given' do
      it 'must return imported records' do
        imported_records = subject.import(output_file)

        expect(imported_records.size).to eq(7)
        expect(imported_records[0]).to be_a(Ronin::DB::IPAddress)
        expect(imported_records[1]).to be_a(Ronin::DB::Port)
        expect(imported_records[2]).to be_a(Ronin::DB::OpenPort)
        expect(imported_records[3]).to be_a(Ronin::DB::IPAddress)
        expect(imported_records[4]).to be_a(Ronin::DB::Port)
        expect(imported_records[5]).to be_a(Ronin::DB::OpenPort)
        expect(imported_records[6]).to be_a(Ronin::DB::IPAddress)
      end
    end
  end

  describe '.import_status' do
    let(:status1) { Masscan::Status.new(status: :open, protocol: :icmp, ip: ip_addr, port: 80, timestamp: Time.now) }
    let(:status2) { Masscan::Status.new(status: :open, protocol: :tcp,  ip: ip_addr, port: 80, timestamp: Time.now) }
    let(:ip_addr) { IPAddr.new('1.2.3.4') }

    context 'when status is :open' do
      context 'when protocol is :icmp' do
        let(:expected_ip_address) { Ronin::DB::IPAddress.find_or_create_by(address: '1.2.3.4', version: 4) }

        it 'must return imported ip address' do
          expect(subject.import_status(status1)).to eq(expected_ip_address)
        end
      end

      context 'when protocol is not :icmp' do
        let(:port)               { Ronin::DB::Port.find_or_create_by(protocol: :tcp, number: 80) }
        let(:ip_address)         { Ronin::DB::IPAddress.find_or_create_by(address: '1.2.3.4', version: 4) }
        let(:expected_open_port) { Ronin::DB::OpenPort.find_or_create_by(ip_address: ip_address, port: port) }

        it 'must return imported open port' do
          expect(subject.import_status(status2)).to eq(expected_open_port)
        end
      end
    end
  end

  describe '.import_open_port_status' do
    let(:ip_addr) { IPAddr.new('1.1.1.1') }
    let(:status)  { Masscan::Status.new(ip: ip_addr, port: 80, protocol: :tcp, timestamp: Time.now, status: :open) }

    context 'when block is given' do
      it 'must yield imported records' do
        yielded_values = []

        subject.import_open_port_status(status) do |value|
          yielded_values << value
        end

        expect(yielded_values.size).to eq(3)
        expect(yielded_values[0]).to be_a(Ronin::DB::IPAddress)
        expect(yielded_values[1]).to be_a(Ronin::DB::Port)
        expect(yielded_values[2]).to be_a(Ronin::DB::OpenPort)
      end
    end

    it 'must return open port' do
      expect(subject.import_open_port_status(status).class).to be(Ronin::DB::OpenPort)
    end
  end

  describe '.import_ip_address' do
    let(:ipv4_address) { IPAddr.new('192.168.1.1') }
    let(:ipv6_address) { IPAddr.new('2001:0db8:85a3:0000:0000:8a2e:0370:7334') }

    it 'imports an IPv4 address' do
      expect(subject.import_ip_address(ipv4_address).address).to eq(ipv4_address.to_s)
    end

    it 'imports an IPv6 address' do
      expect(subject.import_ip_address(ipv6_address).address).to eq(ipv6_address.to_s)
    end

    context 'when a block is given' do
      it 'must yield the imported IP address' do
        yielded_ip_address = nil

        subject.import_ip_address(ipv4_address) do |ip_address|
          yielded_ip_address = ip_address
        end

        expect(yielded_ip_address.address).to eq(ipv4_address.to_s)
      end
    end

    it 'must return the imported IP address' do
      imported_ip_address = subject.import_ip_address(ipv4_address)

      expect(imported_ip_address).to be_a(Ronin::DB::IPAddress)
      expect(imported_ip_address.address).to eq(ipv4_address.to_s)
    end
  end

  describe '.import_port' do
    let(:port_number) { 80 }
    let(:protocol)    { :tcp }

    context 'when block if given' do
      it 'must yeild imported port' do
        yielded_port = nil

        subject.import_port(port_number,protocol) do |port|
          yielded_port = port
        end

        expect(yielded_port).to be_kind_of(Ronin::DB::Port)
        expect(yielded_port.number).to eq(port_number)
      end
    end

    it 'must return imported port' do
      imported_port = subject.import_port(port_number,protocol)
      expect(imported_port).to be_kind_of(Ronin::DB::Port)
      expect(imported_port.number).to eq(port_number)
    end
  end
end
