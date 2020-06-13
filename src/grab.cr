require "./grab/network"
require "./grab/download"

# TODO: Write documentation for `Grab`
module Grab
  VERSION = "0.1.0"

  CONCURRENCY = 8
  BLOCK_SIZE = 4096

  def grab(uri : String, start_at : Int64, end_at : Int64, chan : Channel(Nil), part : Int32)
    spawn do
      headers = HTTP::Headers.new
      headers.add("range", "bytes=#{start_at}-#{end_at}")
      puts "Starting download of part #{part}..."
      HTTP::Client.get(uri, headers) do |response|
        File.write("download.part#{part}", response.body_io)
      end
      chan.send(nil)
    end
  end

  def combine(filename : String)
    parts = (0..(CONCURRENCY-1)).map { |i| "download.part#{i}" }

    File.open(filename, "w") do |file|
      parts.each do |part|
        dl_part = File.new(part)

        loop do
          part_bytes = dl_part.gets(limit: BLOCK_SIZE)
          if part_bytes
            file.print(part_bytes)
          else
            break
          end
        end
      end
    end

    # Delete downloaded parts
    FileUtils.rm(parts)
  end

  uri = ARGV[0]
  file_size = 0_i64

  loop do
    response = HTTP::Client.head(uri)
    if (200..299).includes?(response.status_code)
      file_size = response.headers["content-length"].to_i64
      break
    elsif (301..302).includes?(response.status_code)
      uri = response.headers["location"]
    else
      raise "uh oh"
    end
  end

  # puts response.headers

  chunk_size = file_size // CONCURRENCY

  ch = Channel(Nil).new(CONCURRENCY)
  start_at = 0_i64
  end_at = 0_i64
  ranges = [] of Tuple(Int64, Int64)
  CONCURRENCY.times do |i|
    start_at = i == 0 ? start_at : end_at + 1

    # For the last range, pick up all remaining bytes
    if i == (CONCURRENCY - 1)
      end_at = file_size - 1
    else
      end_at = end_at + chunk_size - 1
    end

    ranges << { start_at, end_at }
  end

  ranges.each_with_index do |range, i|
    grab(uri: uri, start_at: range[0], end_at: range[1], chan: ch, part: i)
  end

  CONCURRENCY.times { ch.receive }

  combine(filename: "fuck.mkv")

end
