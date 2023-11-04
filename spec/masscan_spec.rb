require 'spec_helper'
require 'ronin/masscan'

describe Ronin::Masscan do
  let(:fixtures_dir) { File.join(__dir__,'spec','fixtures') }

  describe ".parse" do
    let(:path) { File.join(fixtures_dir,'masscan.json') }

    it "must return a Masscan::OutputFile object for the given path" do
      output_file = subject.parse(path)

      expect(output_file).to be_kind_of(Masscan::OutputFile)
      expect(output_file.path).to eq(path)
    end
  end
end
