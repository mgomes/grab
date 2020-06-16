require "http/client"

module Grab
  class Network

    @chunk_size : UInt64

    getter :uri, :concurrency, :chunk_size, :ch, :filesize, :filename, :bar

    def initialize(uri : String, concurrency : Int32, filename : String)
      @uri = uri
      @concurrency = concurrency
      @filename = filename
      @filesize = 0_u64
      fetch_file_metadata
      @chunk_size = @filesize // @concurrency
      @ch = Channel(Nil).new(@concurrency)

      @bar = ProgressBar.new
      @bar.complete = "="
      @bar.incomplete = " "
      @bar.total = @filesize
    end

    def grab(start_byte : UInt64, end_byte : UInt64, part : Int32)
      spawn do
        headers = HTTP::Headers.new
        headers.add("Range", "bytes=#{start_byte}-#{end_byte}")
        HTTP::Client.get(uri, headers) do |response|
          File.open("download.part#{part}", "w") do |file|
            write_buffer(response.body_io, file)
          end
        end
        ch.send(nil)
      end
    end

    def fetch_file_metadata
      loop do
        response = HTTP::Client.head(uri)
        if (200..299).includes?(response.status_code)
          @filesize = response.headers["Content-Length"].to_u64
          if filename.blank?
            @filename = get_filename(header: response.headers["Content-Disposition"])
          end

          break
        elsif (301..302).includes?(response.status_code)
          @uri = response.headers["Location"]
        else
          err = "Server returned a #{response.status_code}."
          Grab.fail_with_help(msg: err)
        end
      end
    end

    def fetch
      start_byte = 0_u64
      end_byte = 0_u64
      ranges = [] of Tuple(UInt64, UInt64)

      puts "Downloading #{filename}..."

      concurrency.times do |i|
        start_byte = i == 0 ? start_byte : end_byte + 1

        # For the last range, pick up all remaining bytes
        if i == (concurrency - 1)
          end_byte = filesize - 1
        else
          end_byte = end_byte + chunk_size - 1
        end

        ranges << { start_byte, end_byte }
      end

      ranges.each_with_index do |range, i|
        grab(start_byte: range[0], end_byte: range[1], part: i)
      end

      concurrency.times { ch.receive }
    end

    private def get_filename(header : String) : String
      matches = header.match(/(filename=)(?<filename>.+)\z/)
      if matches.nil? || matches.named_captures["filename"].nil?
        err = "Filename was not sent by the server. Please specify the output filename with -f"
        Grab.fail_with_help(msg: err)
      end

      matches.named_captures["filename"].to_s
    end

    private def write_buffer(src, dst) : Int64
      buffer = uninitialized UInt8[8192]
      count = 0_i64
      while (len = src.read(buffer.to_slice).to_i32) > 0
        dst.write buffer.to_slice[0, len]
        @bar.tick(len)
        count &+= len
      end
      count
    end
  end
end
