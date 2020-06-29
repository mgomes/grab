# Class for working with "content-disposition" headers
class ContentDisposition
  DISPOSITION_REGEX = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/

  def initialize(headers : HTTP::Headers)
    @matches = [] of String | Nil

    if headers.has_key?("Content-Disposition")
      disposition_header = headers["Content-Disposition"]
      @matches = disposition_header.match(DISPOSITION_REGEX).not_nil!.to_a
    end
  end

  def filename
    @matches[1]?
  end
end
