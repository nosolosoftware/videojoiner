module Videojoiner
  module FFMpeg
    class JoinerProcess
      include Runnable

      executes :ffmpeg

      define_command( :start ){ |id, config_file, options|
        "-loglevel verbose
        -f concat
        -i #{config_file}
        -vcodec #{options[:vcodec]}
        -acodec #{options[:acodec]}
        -strict
        -2
        #{options[:filename]}.#{options[:extension]}"
      }

      class << self

        def make_ffmpeg_config( video_list, config_file )
          File.open( "#{config_file}","w" ) do |file|
            video_list.each_pair{ |source, value| file.puts( "file '#{source}'" ) unless value[ :status ] == "invalid" }
          end
        end
      end
    end
  end
end
