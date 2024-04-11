require 'spec_helper'
require 'ronin/masscan/importer'
require 'masscan/output_file'
require 'ronin/db'

RSpec.describe Ronin::Masscan::Importer do
  let(:fixtures_dir) { File.join(__dir__,'fixtures') }
  let(:masscan_path) { File.join(fixtures_dir, 'masscan.json') }
  let(:output_file)  { Masscan::OutputFile.new(masscan_path) }

  before(:all) do
    Ronin::DB.connect('sqlite3::memory:')
  end

  after do
    Ronin::DB::OpenPort.destroy_all
    Ronin::DB::Port.destroy_all
    Ronin::DB::IPAddress.destroy_all
  end

  describe '.import_file' do
    it 'must import the IP and open ports from file' do
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
      it 'must yield the imported records' do
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
      it 'must return the imported records' do
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
    let(:ip)          { '1.2.3.4' }
    let(:ip_addr)     { IPAddr.new(ip) }
    let(:port_number) { 80 }

    let(:status1) do
      Masscan::Status.new(
        status:    :open,
        protocol:  :icmp,
        ip:        ip_addr,
        port:      port_number,
        timestamp: Time.now
      )
    end

    let(:status2) do
      Masscan::Status.new(
        status:    :open,
        protocol:  :tcp,
        ip:        ip_addr,
        port:      port_number,
        timestamp: Time.now
      )
    end

    context 'when status is :open' do
      context 'and when protocol is :icmp' do
        let(:expected_ip_address) do
          Ronin::DB::IPAddress.create(address: ip, version: 4)
        end

        it 'must return imported Ronin::DB::IPAddress' do
          imported_ip_address = subject.import_status(status1)

          expect(imported_ip_address).to be_a(Ronin::DB::IPAddress)
          expect(imported_ip_address.address).to eq(ip)
        end
      end

      context 'and when protocol is not :icmp' do
        it 'must return imported Ronin::DB::OpenPort' do
          imported_open_port = subject.import_status(status2)

          expect(imported_open_port).to be_a(Ronin::DB::OpenPort)
          expect(imported_open_port.port).to be_a(Ronin::DB::Port)
          expect(imported_open_port.port.number).to eq(port_number)
          expect(imported_open_port.ip_address).to be_a(Ronin::DB::IPAddress)
          expect(imported_open_port.ip_address.address).to eq(ip)
        end
      end
    end
  end

  describe '.import_open_port_status' do
    let(:ip)          { '1.1.1.1' }
    let(:ip_addr)     { IPAddr.new(ip) }
    let(:port_number) { 80 }

    let(:status) do
      Masscan::Status.new(
        ip:        ip_addr,
        port:      port_number,
        protocol:  :tcp,
        timestamp: Time.now,
        status:    :open
      )
    end

    context 'when block is given' do
      it 'must yield the imported records' do
        yielded_values = []

        subject.import_open_port_status(status) do |value|
          yielded_values << value
        end

        expect(yielded_values.size).to eq(3)
        expect(yielded_values[0]).to be_a(Ronin::DB::IPAddress)
        expect(yielded_values[0].address).to eq(ip)
        expect(yielded_values[1]).to be_a(Ronin::DB::Port)
        expect(yielded_values[1].number).to eq(port_number)
        expect(yielded_values[2]).to be_a(Ronin::DB::OpenPort)
      end
    end

    it 'must return the imported Ronin::DB::OpenPort' do
      imported_open_port = subject.import_open_port_status(status)

      expect(imported_open_port).to be_a(Ronin::DB::OpenPort)
      expect(imported_open_port.port).to be_a(Ronin::DB::Port)
      expect(imported_open_port.port.number).to eq(port_number)
      expect(imported_open_port.ip_address).to be_a(Ronin::DB::IPAddress)
      expect(imported_open_port.ip_address.address).to eq(ip)
    end
  end

  describe '.import_ip_address' do
    let(:ip)      { '1.1.1.1' }
    let(:ip_addr) { IPAddr.new(ip) }

    it 'must return the imported Ronin::DB::IPAddress' do
      imported_ip_address = subject.import_ip_address(ip_addr)

      expect(imported_ip_address).to be_a(Ronin::DB::IPAddress)
      expect(imported_ip_address.address).to eq(ip)
    end

    context 'when a block is given' do
      it 'must yield the imported Ronin::DB::IPAddress' do
        yielded_ip_address = nil

        subject.import_ip_address(ip_addr) do |ip_address|
          yielded_ip_address = ip_address
        end

        expect(yielded_ip_address.address).to eq(ip)
      end
    end

    context "when given an IPv4 address" do
      let(:ipv4)      { '192.168.1.1' }
      let(:ipv4_addr) { IPAddr.new(ipv4) }

      it 'imports an IPv4 address and return a Ronin::DB::IPAddress record' do
        imported_ip_address = subject.import_ip_address(ipv4_addr)

        expect(imported_ip_address).to be_a(Ronin::DB::IPAddress)
        expect(imported_ip_address.address).to eq(ipv4)
        expect(imported_ip_address.version).to eq(4)
      end
    end

    context "when given an IPv6 address" do
      let(:ipv6)      { '2001:db8:85a3::8a2e:370:7334' }
      let(:ipv6_addr) { IPAddr.new(ipv6) }

      it 'imports an IPv6 address and return a Ronin::DB::IPAddress record' do
        imported_ip_address = subject.import_ip_address(ipv6_addr)

        expect(imported_ip_address).to be_a(Ronin::DB::IPAddress)
        expect(imported_ip_address.address).to eq(ipv6)
        expect(imported_ip_address.version).to eq(6)
      end
    end
  end

  describe '.import_port' do
    let(:port_number) { 80 }
    let(:protocol)    { :tcp }

    it 'must return the imported Ronin::DB::Port' do
      imported_port = subject.import_port(port_number,protocol)

      expect(imported_port).to be_a(Ronin::DB::Port)
      expect(imported_port.number).to eq(port_number)
      expect(imported_port.protocol).to eq(protocol.to_s)
    end

    context 'when block if given' do
      it 'must yeild the imported Ronin::DB::Port' do
        yielded_port = nil

        subject.import_port(port_number,protocol) do |port|
          yielded_port = port
        end

        expect(yielded_port).to be_kind_of(Ronin::DB::Port)
        expect(yielded_port.number).to eq(port_number)
        expect(yielded_port.protocol).to eq(protocol.to_s)
      end
    end
  end
end
