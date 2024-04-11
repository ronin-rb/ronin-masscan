require 'spec_helper'
require 'ronin/masscan/cli/commands/print'
require_relative 'man_page_example'

describe Ronin::Masscan::CLI::Commands::Print do
  include_examples "man_page"

  let(:fixtures_dir) { File.expand_path(File.join(__dir__,'..','..','fixtures')) }
  let(:masscan_path) { File.join(fixtures_dir, 'masscan.json') }
  let(:output_file)  { Masscan::OutputFile.new(masscan_path) }
  let(:records)      { output_file.each }

  describe "#run" do
    it "must print all records grouped by IP and port/protocol from the masscan file" do
      expect {
        subject.run(masscan_path)
      }.to output(
        <<~OUTPUT
          [ 93.184.216.34 ]

            80/tcp	open
              http_server	ECS (sec/974D)
              html_title	404 - Not Found
              http
                HTTP/1.0 404 Not Found
                Content-Type: text/html
                Date: Thu, 26 Aug 2021 06:50:24 GMT
                Server: ECS (sec/974D)
                Content-Length: 345
                Connection: close

            443/tcp	open
              ssl3	TLS/1.1 cipher:0xc013, www.example.org, www.example.org, example.com, example.edu, example.net, example.org, www.example.com, www.example.edu, www.example.net
              x509	MIIG1TCCBb2gAwIBAgIQD74IsIVNBXOKsMzhya/uyTANBgkqhkiG9w0BAQsFADBPMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMSkwJwYDVQQDEyBEaWdpQ2VydCBUTFMgUlNBIFNIQTI1NiAyMDIwIENBMTAeFw0yMDExMjQwMDAwMDBaFw0yMTEyMjUyMzU5NTlaMIGQMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLTG9zIEFuZ2VsZXMxPDA6BgNVBAoTM0ludGVybmV0IENvcnBvcmF0aW9uIGZvciBBc3NpZ25lZCBOYW1lcyBhbmQgTnVtYmVyczEYMBYGA1UEAxMPd3d3LmV4YW1wbGUub3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuvzuzMoKCP8Okx2zvgucA5YinrFPEK5RQP1TX7PEYUAoBO6i5hIAsIKFmFxtW2sghERilU5rdnxQcF3fEx3sY4OtY6VSBPLPhLrbKozHLrQ8ZN/rYTb+hgNUeT7NA1mP78IEkxAj4qG5tli4Jq41aCbUlCt7equGXokImhC+UY5IpQEZS0tKD4vu2ksZ04Qetp0k8jWdAvMA27W3EwgHHNeVGWbJPC0Dn7RqPw13r7hFyS5TpleywjdY1nB7ad6kcZXZbEcaFZ7ZuerA6RkPGE+PsnZRb1oFJkYoXimsuvkVFhWeHQXCGC1cuDWSrM3cpQvOzKH2vS7d15+zGls4IwIDAQABo4IDaTCCA2UwHwYDVR0jBBgwFoAUt2ui6qiqhIx56rTaD5iyxZV2ufQwHQYDVR0OBBYEFCYa+OSxsHKEztqBBtInmPvtOj0XMIGBBgNVHREEejB4gg93d3cuZXhhbXBsZS5vcmeCC2V4YW1wbGUuY29tggtleGFtcGxlLmVkdYILZXhhbXBsZS5uZXSCC2V4YW1wbGUub3Jngg93d3cuZXhhbXBsZS5jb22CD3d3dy5leGFtcGxlLmVkdYIPd3d3LmV4YW1wbGUubmV0MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwgYsGA1UdHwSBgzCBgDA+oDygOoY4aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VExTUlNBU0hBMjU2MjAyMENBMS5jcmwwPqA8oDqGOGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv

            0/icmp	open
        OUTPUT
      ).to_stdout
    end
  end

  describe "#print_records" do
    it "must print all records grouped by IP and port/protocol" do
      expect {
        subject.print_records(records)
      }.to output(
        <<~OUTPUT
          [ 93.184.216.34 ]

            80/tcp	open
              http_server	ECS (sec/974D)
              html_title	404 - Not Found
              http
                HTTP/1.0 404 Not Found
                Content-Type: text/html
                Date: Thu, 26 Aug 2021 06:50:24 GMT
                Server: ECS (sec/974D)
                Content-Length: 345
                Connection: close

            443/tcp	open
              ssl3	TLS/1.1 cipher:0xc013, www.example.org, www.example.org, example.com, example.edu, example.net, example.org, www.example.com, www.example.edu, www.example.net
              x509	MIIG1TCCBb2gAwIBAgIQD74IsIVNBXOKsMzhya/uyTANBgkqhkiG9w0BAQsFADBPMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMSkwJwYDVQQDEyBEaWdpQ2VydCBUTFMgUlNBIFNIQTI1NiAyMDIwIENBMTAeFw0yMDExMjQwMDAwMDBaFw0yMTEyMjUyMzU5NTlaMIGQMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLTG9zIEFuZ2VsZXMxPDA6BgNVBAoTM0ludGVybmV0IENvcnBvcmF0aW9uIGZvciBBc3NpZ25lZCBOYW1lcyBhbmQgTnVtYmVyczEYMBYGA1UEAxMPd3d3LmV4YW1wbGUub3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuvzuzMoKCP8Okx2zvgucA5YinrFPEK5RQP1TX7PEYUAoBO6i5hIAsIKFmFxtW2sghERilU5rdnxQcF3fEx3sY4OtY6VSBPLPhLrbKozHLrQ8ZN/rYTb+hgNUeT7NA1mP78IEkxAj4qG5tli4Jq41aCbUlCt7equGXokImhC+UY5IpQEZS0tKD4vu2ksZ04Qetp0k8jWdAvMA27W3EwgHHNeVGWbJPC0Dn7RqPw13r7hFyS5TpleywjdY1nB7ad6kcZXZbEcaFZ7ZuerA6RkPGE+PsnZRb1oFJkYoXimsuvkVFhWeHQXCGC1cuDWSrM3cpQvOzKH2vS7d15+zGls4IwIDAQABo4IDaTCCA2UwHwYDVR0jBBgwFoAUt2ui6qiqhIx56rTaD5iyxZV2ufQwHQYDVR0OBBYEFCYa+OSxsHKEztqBBtInmPvtOj0XMIGBBgNVHREEejB4gg93d3cuZXhhbXBsZS5vcmeCC2V4YW1wbGUuY29tggtleGFtcGxlLmVkdYILZXhhbXBsZS5uZXSCC2V4YW1wbGUub3Jngg93d3cuZXhhbXBsZS5jb22CD3d3dy5leGFtcGxlLmVkdYIPd3d3LmV4YW1wbGUubmV0MA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwgYsGA1UdHwSBgzCBgDA+oDygOoY4aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VExTUlNBU0hBMjU2MjAyMENBMS5jcmwwPqA8oDqGOGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv

            0/icmp	open
        OUTPUT
      ).to_stdout
    end
  end

  describe "#print_status_record" do
    let(:record) do
      records.find { |record| record.kind_of?(Masscan::Status) }
    end

    it "must print the port/protocol and status of the port" do
      expect {
        subject.print_status_record(record)
      }.to output("80/tcp\topen#{$/}").to_stdout
    end
  end

  describe "#print_banner_record" do
    context "when the banner's #payload does not contain a newline" do
      let(:record) do
        records.find do |record|
          record.kind_of?(Masscan::Banner) &&
            record.app_protocol == :http_server
        end
      end

      it "must print the banner's #app_protocol and #payload" do
        expect {
          subject.print_banner_record(record)
        }.to output("http_server\tECS (sec/974D)#{$/}").to_stdout
      end
    end

    context "when the banner's #payload contains multiple lines" do
      let(:record) do
        records.find do |record|
          record.kind_of?(Masscan::Banner) &&
            record.app_protocol == :http
        end
      end

      it "must print the banner's #app_protocol and #payload" do
        expect {
          subject.print_banner_record(record)
        }.to output(
          <<~OUTPUT
            http
              HTTP/1.0 404 Not Found
              Content-Type: text/html
              Date: Thu, 26 Aug 2021 06:50:24 GMT
              Server: ECS (sec/974D)
              Content-Length: 345
              Connection: close
          OUTPUT
        ).to_stdout
      end
    end
  end
end
