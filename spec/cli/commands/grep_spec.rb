require 'spec_helper'
require 'ronin/masscan/cli/commands/grep'
require_relative 'man_page_example'

require 'stringio'

describe Ronin::Masscan::CLI::Commands::Grep do
  include_examples "man_page"

  let(:stdout) { StringIO.new }

  before  { allow(stdout).to receive(:tty?).and_return(true) }
  subject { described_class.new(stdout: stdout) }

  let(:fixtures_dir) { File.expand_path(File.join(__dir__,'..','..','fixtures')) }
  let(:masscan_path) { File.join(fixtures_dir, 'masscan.json') }
  let(:output_file)  { Masscan::OutputFile.new(masscan_path) }
  let(:records)      { output_file.each }

  let(:pattern) { 'html' }
  let(:highlighted_pattern) { subject.colors.red(pattern) }

  describe "#run" do
    it "must print the masscan banner records from the masscan file that contain the pattern" do
      subject.run(pattern,masscan_path)

      expect(stdout.string).to eq(
        <<~OUTPUT
          [ 93.184.216.34 ]

            80/tcp
              #{highlighted_pattern}_title	404 - Not Found
              http
                HTTP/1.0 404 Not Found
                Content-Type: text/#{highlighted_pattern}
                Date: Thu, 26 Aug 2021 06:50:24 GMT
                Server: ECS (sec/974D)
                Content-Length: 345
                Connection: close

        OUTPUT
      )
    end
  end

  describe "#grep_records" do
    it "must return a lazy enumerator with all banner records that contain the pattern in their #app_protocol or #payload fields" do
      matching_records = subject.grep_records(output_file,pattern)

      expect(matching_records).to be_kind_of(Enumerator::Lazy)
      expect(matching_records.to_a).to eq(
        records.filter do |record|
          record.kind_of?(Masscan::Banner) && (
            record.app_protocol.match(pattern) ||
            record.payload.match(pattern)
          )
        end
      )
    end
  end

  describe "#match_record" do
    context "when given a Masscan::Status record" do
      let(:record) do
        records.find { |record| record.kind_of?(Masscan::Status) }
      end

      it "must return false" do
        expect(subject.match_record(record,pattern)).to be_falsy
      end
    end

    context "when given a Masscan::Banner record" do
      let(:record) do
        records.find { |record| record.kind_of?(Masscan::Banner) }
      end

      context "and the pattern exists within the #app_protocol field" do
        let(:pattern) { 'html' }
        let(:record) do
          records.find do |record|
            record.kind_of?(Masscan::Banner) &&
              record.app_protocol == :html_title
          end
        end

        it "must return true" do
          expect(subject.match_record(record,pattern)).to be_truthy
        end
      end

      context "and the pattern exists within the #payload field" do
        let(:pattern) { 'ECS' }
        let(:record) do
          records.find do |record|
            record.kind_of?(Masscan::Banner) &&
              record.app_protocol == :http
          end
        end

        it "must return true" do
          expect(subject.match_record(record,pattern)).to be_truthy
        end
      end

      context "but the pattern does not exists within the #app_protocol or #payload fields" do
        let(:pattern) { 'foo' }
        let(:record) do
          records.find { |record| record.kind_of?(Masscan::Banner) }
        end

        it "must return false" do
          expect(subject.match_record(record,pattern)).to be_falsy
        end
      end
    end
  end

  describe "#highlight_records" do
    let(:matching_records) do
      records.filter do |record|
        record.kind_of?(Masscan::Banner) && (
          record.app_protocol.match(pattern) ||
          record.payload.match(pattern)
        )
      end
    end

    it "must print the records, grouped by IP and port/protocol, with the pattern highlighted" do
      subject.highlight_records(matching_records,pattern)

      expect(stdout.string).to eq(
        <<~OUTPUT
          [ 93.184.216.34 ]

            80/tcp
              #{highlighted_pattern}_title	404 - Not Found
              http
                HTTP/1.0 404 Not Found
                Content-Type: text/#{highlighted_pattern}
                Date: Thu, 26 Aug 2021 06:50:24 GMT
                Server: ECS (sec/974D)
                Content-Length: 345
                Connection: close

        OUTPUT
      )
    end
  end

  describe "#highlight_record" do
    context "when given a Masscan::Banner record" do
      let(:record) do
        records.find { |record| record.kind_of?(Masscan::Banner) }
      end

      context "and the pattern exists within the #app_protocol field" do
        let(:pattern) { 'html' }
        let(:record) do
          records.find do |record|
            record.kind_of?(Masscan::Banner) &&
              record.app_protocol == :html_title
          end
        end

        it "must print the banner record with the pattern highlighted in the #app_protocol part" do
          subject.highlight_record(record,pattern)

          expect(stdout.string).to eq(
            "#{highlighted_pattern}_title	404 - Not Found#{$/}"
          )
        end
      end

      context "and the pattern exists within the #payload field" do
        let(:pattern) { 'ECS' }
        let(:record) do
          records.find do |record|
            record.kind_of?(Masscan::Banner) &&
              record.app_protocol == :http
          end
        end

        it "must print the banner record with the pattern highlighted in the #payload part" do
          subject.highlight_record(record,pattern)

          expect(stdout.string).to eq(
            <<~OUTPUT
              http
                HTTP/1.0 404 Not Found
                Content-Type: text/html
                Date: Thu, 26 Aug 2021 06:50:24 GMT
                Server: #{highlighted_pattern} (sec/974D)
                Content-Length: 345
                Connection: close
            OUTPUT
          )
        end
      end
    end
  end

  describe "#highlight_banner_record" do
    context "and the pattern exists within the #app_protocol field" do
      let(:pattern) { 'html' }
      let(:record) do
        records.find do |record|
          record.kind_of?(Masscan::Banner) &&
            record.app_protocol == :html_title
        end
      end

      it "must print the banner record with the pattern highlighted in the #app_protocol part" do
        subject.highlight_banner_record(record,pattern)

        expect(stdout.string).to eq(
          "#{highlighted_pattern}_title	404 - Not Found#{$/}"
        )
      end
    end

    context "and the pattern exists within the #payload field" do
      let(:pattern) { 'ECS' }
      let(:record) do
        records.find do |record|
          record.kind_of?(Masscan::Banner) &&
            record.app_protocol == :http
        end
      end

      it "must print the banner record with the pattern highlighted in the #payload part" do
        subject.highlight_banner_record(record,pattern)

        expect(stdout.string).to eq(
          <<~OUTPUT
            http
              HTTP/1.0 404 Not Found
              Content-Type: text/html
              Date: Thu, 26 Aug 2021 06:50:24 GMT
              Server: #{highlighted_pattern} (sec/974D)
              Content-Length: 345
              Connection: close
          OUTPUT
        )
      end
    end
  end
end
