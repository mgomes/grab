require "file_utils"
require "./utils/progress_bar"

module Grab
  class Download
    BLOCK_SIZE = 8192

    getter :filename, :num_parts

    def initialize(filename : String, num_parts : Int32, filesize : UInt64)
      @filename = filename
      @num_parts = num_parts
      @filesize = filesize

      @bar = ProgressBar.new
      @bar.complete = "="
      @bar.incomplete = " "
      @bar.total = @filesize
    end

    def combine
      parts = (0..(num_parts-1)).map { |i| "download.part#{i}" }

      puts "\n\nCombining downloaded parts..."

      File.open(filename, "w") do |file|
        parts.each do |part|
          dl_part = File.open(part)

          loop do
            slice = Bytes.new(BLOCK_SIZE)
            bytes_read = dl_part.read(slice)
            if bytes_read > 0
              # we may have read < BLOCK_SIZE, like in the case
              # where we are at the end of the file
              file.write(slice[0..(bytes_read - 1)])
              @bar.tick(bytes_read)
            else
              break
            end
          end
        end
      end

      # Delete downloaded parts
      puts "\n\nCleaning up..."
      FileUtils.rm(parts)
    end
  end
end
