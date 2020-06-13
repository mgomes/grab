require "file_utils"

module Grab
  class Download
    BLOCK_SIZE = 4096

    getter :filename, :num_parts

    def initialize(filename : String, num_parts : Int32)
      @filename = filename
      @num_parts = num_parts
    end

    def combine
      parts = (0..(num_parts-1)).map { |i| "download.part#{i}" }

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
  end
end
