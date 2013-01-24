module Videojoiner
  module FFMpeg
    class Joiner

      class ConfigurationError < RuntimeError; end

      attr_reader :id, :video_list, :output_file, :config_file, :process

      # Initialize a new joiner object
      # @param id [string] The joiner job ID
      # @param video_sources [array] An array of video files
      def initialize( id, video_sources )
        @id = id
        @video_list = self.class.probe_videos( video_sources )
        @output_file = ""
        @process = Videojoiner::FFMpeg::JoinerProcess.new
        @process.log_path = "log/"
        # Path to a text file with the list of videos to be used for ffmpeg's concat demuxer
        @config_file = "#{self.class.config_path}#{id}_#{Time.now.to_i}.ffmpeg"
      end

      # Starts the video joiner job and adds it to the job list
      # @param opts [hash] A hash with configuration options for the transcoder
      def create( opts = {} )
        # FFMpeg options hash
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

      # Delete a previously created video joiner job and remove it from the job list
      # @return true if the job removal was sucessful
      # @return false otherwise
      def delete
        if self.class.exist?( @id )
          self.class.remove_job( @id )
          File.delete( "#{@config_file}" ) unless !File.exist?( "#{@config_file}" )
          File.delete( "#{@output_file}" ) unless !File.exist?( "#{@output_file}" )
        else
          false
        end
      end

      # Method that check if the join process has finished
      # @return true if the job has finished
      # @return false otherwise
      def finished?
        output = @process.std_err
        output.include?( "No more output streams to write to, finishing." ) && output.include?( "muxing overhead" ) 
      end

      class << self

        attr_accessor :config_path

        # Check that the video sources passed has parameters are valid for the joining process
        # @param video_sources [array] an array with the source videos
        # @return a hash with the source videos and its validation status
        def probe_videos( video_sources )
          video_list = Hash.new

          video_sources.each do |source|
            inspector = RVideo::Inspector.new( :file => "#{source}" )
            if ( inspector.valid? ) && ( inspector.duration > 0 )
              video_list.store( source, 'valid' )
            else
              video_list.store( source, 'invalid' )
            end
          end
          video_list
        end

        # Check if the job list is empty
        # @return true if the list is empty
        # @return false otherwise
        def empty?
          joiner_list.empty?
        end

        # Fetches a job from the job list by it ID
        # @param id [string] the job ID
        # @return the job with that ID
        def fetch( id )
          joiner_list.fetch( id ) unless empty?
        end

        # Check if a job exist in the job list
        # @param id [string] the job ID
        # @return true if the job exist
        # @return false otherwise
        def exist?( id )
          joiner_list.has_key?( id ) unless empty?
        end

        # Clears the job list
        def clear_list
          joiner_list.clear unless empty?
        end

        # Adds a video joiner job to the job list
        # @param id [string] the job ID
        # @param joiner  [Videojoiner::FFMpeg::Joiner] the joiner job object
        def add_job( id, joiner )
          joiner_list.store( id, joiner )
        end

        # Removes a video joiner job from the job list
        # @param id [string] the job ID
        def remove_job( id )
          joiner_list.fetch( id ).process.stop unless joiner_list.fetch( id ).process.pid == nil
          joiner_list.delete( id )
        end

        # Yields the current object to configure some required parameters
        def configure( &block )
          yield self
        end

        private

        # Return the joiner job list, or generate an empty list if it don't exist already
        # It requires the setting of the config_path parameter previously
        def joiner_list
          raise ConfigurationError, "Missing configuration: please check Joiner.config_path" unless configured?
          raise ConfigPathError, "Config path not exist" unless Dir.exist?( config_path )
          @joiner_list ||= Hash.new
        end

        # Return the configuration status of the object
        # @return the configuration path
        # @return false otherwise
        def configured?
          config_path
        end
      end
    end
  end
end
