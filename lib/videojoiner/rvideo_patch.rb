class RVideo::Inspector
  def initialize(options = {})
    if options[:raw_response]
      @raw_response = options[:raw_response]
    elsif options[:file]
      if options[:ffmpeg_binary]
        @ffmpeg_binary = options[:ffmpeg_binary]
        raise RuntimeError, "ffmpeg could not be found (trying #{@ffmpeg_binary})" unless FileTest.exist?(@ffmpeg_binary)
      else
        # assume it is in the unix path
        raise RuntimeError, 'ffmpeg could not be found (expected ffmpeg to be found in the Unix path)' unless FileTest.exist?(`which ffmpeg`.chomp)
        @ffmpeg_binary = "ffmpeg"
      end

      file = options[:file]
      @filename = File.basename(file)
      @path = File.dirname(file)
      @full_filename = file
      raise ArgumentError, "File not found (#{file})" unless FileTest.exist?(file.gsub("\"",""))
      @raw_response = `#{@ffmpeg_binary} -i #{@full_filename} 2>&1`
    else
      raise ArgumentError, "Must supply either an input file or a pregenerated response" if options[:raw_response].nil? and file.nil?
    end

    metadata = /(Input \#.*)\n/m.match(@raw_response)

    if /Unknown format/i.match(@raw_response) || metadata.nil?
      @unknown_format = true
    elsif /Duration: N\/A|bitrate: N\/A/im.match(@raw_response)
      @unreadable_file = true
      @raw_metadata = metadata[1] # in this case, we can at least still get the container type
    else
      @raw_metadata = metadata[1]
    end
  end
end
