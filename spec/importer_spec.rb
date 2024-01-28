require 'spec_helper'
require 'ronin/masscan/importer'
require 'masscan/output_file'
require 'ronin/db'

RSpec.describe Ronin::Masscan::Importer do
  let(:masscan_path) { File.expand_path(File.join(__dir__, '..', 'spec', 'fixtures', 'masscan.json')) }
  let(:output_file)  { Masscan::OutputFile.new(masscan_path) }

  before(:all) do
    Ronin::DB.connect('sqlite3::memory:')
  end

  after(:all) do
    Ronin::DB::IPAddress.destroy_all
    # Ronin::DB::Port.destroy_all
    Ronin::DB::OpenPort.destroy_all
  end

  describe '.import_file' do
    let(:expected_values) do
      [
        Ronin::DB::IPAddress,
        Ronin::DB::Port,
        Ronin::DB::OpenPort,
        Ronin::DB::IPAddress,
        Ronin::DB::Port,
        Ronin::DB::OpenPort,
        Ronin::DB::IPAddress
      ]
    end

    it 'must import records from file' do
      yielded_values = []

      subject.import_file(masscan_path) do |value|
        yielded_values << value
      end

      expect(yielded_values.size).to eq(7)
      expect(yielded_values.map(&:class)).to match(expected_values)
    end
  end

  describe '.import' do
    let(:expected_values) do
      [
        Ronin::DB::IPAddress,
        Ronin::DB::Port,
        Ronin::DB::OpenPort,
        Ronin::DB::IPAddress,
        Ronin::DB::Port,
        Ronin::DB::OpenPort,
        Ronin::DB::IPAddress
      ]
    end

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

        subject.import_file(masscan_path) do |value|
          yielded_values << value
        end

        expect(yielded_values.size).to eq(7)
        expect(yielded_values.map(&:class)).to match(expected_values)
      end
    end

    context 'when no block is given' do
      it 'must return imported records' do
        expect(subject.import(output_file).size).to eq(7)
        expect(subject.import(output_file).map(&:class)).to match(expected_values)
      end
    end
  end

  describe '.import_status' do
    let(:status1) { instance_double('Masscan::Status', status: :open, protocol: :icmp, ip: ip_addr) }
    let(:status2) { instance_double('Masscan::Status', status: :open, protocol: :tcp) }
    let(:ip_addr) { IPAddr.new('1.1.1.1') }

    context 'when status is :open' do
      context 'when protocol is :icmp' do
        it 'must import ip address' do
          expect(subject).to receive(:import_ip_address).with(ip_addr)

          subject.import_status(status1)
        end
      end

      context 'when protocol is not :icmp' do
        it 'must import open port' do
          expect(subject).to receive(:import_open_port_status).with(status2)

          subject.import_status(status2)
        end
      end
    end
  end

  describe '.import_open_port_status' do
    let(:ip_addr)   { IPAddr.new('1.1.1.1') }
    let(:status)    { instance_double('Masscan::Status', ip: ip_addr, port: 80, protocol: :tcp, timestamp: Time.now) }

    context 'when block is given' do
      it 'must yield imported records' do
        yielded_values = []

        subject.import_open_port_status(status) do |value|
          yielded_values << value
        end

        expect(yielded_values.size).to eq(3)
        expect(yielded_values.map(&:class)).to match([Ronin::DB::IPAddress, Ronin::DB::Port, Ronin::DB::OpenPort])
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

      expect(imported_ip_address.class).to be(Ronin::DB::IPAddress)
      expect(imported_ip_address.address).to eq(ipv4_address.to_s)
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
