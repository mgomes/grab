require "../spec_helper"

describe ContentDisposition do
  it "should return the filename" do
    headers = HTTP::Headers.new
    headers["Content-Disposition"] = "attachment; filename=filename.jpg"
    cd = ContentDisposition.new(headers)
    cd.filename.should eq "filename.jpg"

    headers["Content-Disposition"] = "attachment;filename=\"Stereo Foo - Cohete Amigo.wav\""
    cd = ContentDisposition.new(headers)
    cd.filename.should eq "Stereo Foo - Cohete Amigo.wav"

    headers["Content-Disposition"] = "attachment;filename=\"há日本語.iso\""
    cd = ContentDisposition.new(headers)
    cd.filename.should eq "há日本語.iso"

    headers["Content-Disposition"] = "attachment;filename=movie.mkv"
    cd = ContentDisposition.new(headers)
    cd.filename.should eq "movie.mkv"
  end

  it "should return nil if the header is not present" do
    headers = HTTP::Headers.new
    cd = ContentDisposition.new(headers)
    cd.filename.should be_nil
  end

  it "should return the filename if wrapped in double quotes" do
    headers = HTTP::Headers.new
    headers["Content-Disposition"] = "attachment; filename=\"filename.jpg\""
    cd = ContentDisposition.new(headers)
    cd.filename.should eq "filename.jpg"
  end
end
