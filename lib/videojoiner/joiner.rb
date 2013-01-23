module Videojoiner
  module FFMpeg
    class Joiner

      class ConfigurationError < RuntimeError; end

      attr_reader :id, :video_list, :output_file, :config_file, :process

      def initialize( id, video_sources )
        @id = id
        @video_list = self.class.probe_videos( video_sources )
        @output_file = ""
        @process = Videojoiner::FFMpeg::JoinerProcess.new
        @process.log_path = "log/"
        @config_file = "#{self.class.config_path}#{id}_#{Time.now.to_i}.ffmpeg"
      end

      def create( opts = {} )
        options = {
          :vcodec    => $1 || "copy",
          :acodec    => $2 || "copy",
          :filename  => $3 || "#{@id}_#{Time.now.to_i}",
          :extension => $4 || "mp4"
        }.merge( opts )

        if self.class.exist?( @id )
          false
        else
          Videojoiner::FFMpeg::JoinerProcess.make_ffmpeg_config( @video_list, @config_file )
          @process.start( @id, @config_file, options )
          self.class.add_job( @id, self )
          @output_file = "#{options[:filename]}.#{options[:extension]}"
        end
      end

      def delete
        if self.class.exist?( @id )
          self.class.remove_job( @id )
          File.delete( "#{@config_file}" ) unless !File.exist?( "#{@config_file}" )
          File.delete( "#{@output_file}" ) unless !File.exist?( "#{@output_file}" )
        else
          false
        end
      end

      def finished?
        output = @process.std_err
        output.include?( "No more output streams to write to, finishing." ) && output.include?( "muxing overhead" ) 
      end

      class << self

        attr_accessor :config_path

        def probe_videos( video_sources )
          video_list = Hash.new

          video_sources.each do |source|
            if RVideo::Inspector.new( :file => "#{source}" ).valid?
              video_list.store( source, 'valid' )
            else
              video_list.store( source, 'invalid' )
            end
          end
          video_list
        end

        def empty?
          joiner_list.empty?
        end

        def fetch( id )
          joiner_list.fetch( id ) unless empty?
        end

        def exist?( id )
          joiner_list.has_key?( id ) unless empty?
        end

        def clear_list
          joiner_list.clear unless empty?
        end

        def add_job( id, joiner )
          joiner_list.store( id, joiner )
        end

        def remove_job( id )
          joiner_list.fetch( id ).process.stop unless joiner_list.fetch( id ).process.pid == nil
          joiner_list.delete( id )
        end

        def configure( &block )
          yield self
        end

        private

        def joiner_list
          raise ConfigurationError, "Missing configuration: please check Joiner.config_path" unless configured?
          raise ConfigPathError, "Config path not exist" unless Dir.exist?( config_path )
          @joiner_list ||= Hash.new
        end

        def configured?
          config_path
        end
      end
    end
  end
end
