require "mime/media_type"

class ContentDisposition
  getter filename : String | Nil

  def initialize(headers : HTTP::Headers)
    if headers.has_key?("Content-Disposition")
      disposition_header = headers["Content-Disposition"]
      parse_disposition(disposition_header)
    end
  end

  private def parse_disposition(disposition_header)
    media_type = MIME::MediaType.parse(disposition_header)
    @filename = media_type["filename"]
  end
end
