require "option_parser"
require "./grab/network"
require "./grab/download"

# TODO: Write documentation for `Grab`
module Grab
  VERSION = "0.9.0"

  concurrency = 8_i32
  filename = ""
  uri = ""

  # Prints usage error in the program arguments and terminates the program.
  def self.fail_with_help(msg : String)
    STDERR.puts "ERROR: #{msg}"
    exit(1)
  end

  OptionParser.parse! do |parser|
    parser.banner = <<-TEXT
      Downloads a file utilizing concurrent HTTP connections to accelerate the download speed.

      Usage: grab <URI> [arguments]
    TEXT

    parser.on("-v", "--version", "Prints the program version") do
      puts VERSION
      exit
    end

    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit
    end

    parser.on "-c NUMBER", "--concurrency=NUMBER", "The number of concurrent HTTP connections (default: 8)" do |num|
      concurrency = num.to_i32
    end

    parser.on "-f FILENAME", "--filename=NAME", "The local filename to store the download (default: server specified)" do |name|
      filename = name
    end

    if ARGV[0]?
      uri = ARGV[0]
    else
      msg = "missing URI\n#{parser}"
      Grab.fail_with_help(msg)
    end

    parser.missing_option do |option_flag|
      msg = "#{option_flag} expected an argument\n#{parser}"
      Grab.fail_with_help(msg)
    end

    parser.invalid_option do |option_flag|
      msg = "unrecognized option #{option_flag}\n#{parser}"
      Grab.fail_with_help(msg)
    end
  end

  network = Grab::Network.new(
    uri: uri,
    concurrency: concurrency,
    filename: filename
  )
  network.fetch

  download = Grab::Download.new(
    filename: network.filename,
    num_parts: concurrency,
    filesize: network.filesize
  )
  download.combine

  puts "\nDone!"
end
