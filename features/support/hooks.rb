After do |scenario|
  Dir.new( "video_root" ).each do |filename|
    if /.*\.(mp4|avi|mpg)/ =~ filename
      FileUtils.rm( "video_root/#{filename}" )
    end
  end
  Dir.new( "/tmp/" ).each do |filename|
    if /.*\.(ffmpeg|mp4)/ =~ filename
      FileUtils.rm( "/tmp/#{filename}" )
    end
  end
  Dir.new( "log/" ).each do |filename|
    if /.*\.(log)/ =~ filename
      FileUtils.rm( "log/#{filename}" )
    end
  end
  Videojoiner::FFMpeg::Joiner.clear_list
end
