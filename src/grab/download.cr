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
          dl_part = File.new(part)

          loop do
            part_bytes = dl_part.gets(limit: BLOCK_SIZE)
            if part_bytes
              file.print(part_bytes)
              @bar.tick(BLOCK_SIZE)
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
