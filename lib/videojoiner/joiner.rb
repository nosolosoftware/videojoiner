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
        @output_file = ""
        @video_list = self.class.probe_videos( video_sources )
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

      # Method that returns the total file size of the valid input videos
      # @return the total file size
      def size
        total_size = 0
        @video_list.each_value{ | element | total_size += element[ :size ] unless element[ :status ] == 'invalid' }
        total_size
      end

      class << self

        attr_accessor :config_path

        # Check if the job list is empty
        # @return true if the list is empty
        # @return false otherwise
        def empty?
          job_list.empty?
        end

        # Fetches a job from the job list by it ID
        # @param id [string] the job ID
        # @return the job with that ID
        # @return false otherwise
        def fetch( id )
          begin
            job_list.fetch( id ) unless empty?
          rescue KeyError
            false
          end
        end

        # Check if a job exist in the job list
        # @param id [string] the job ID
        # @return true if the job exist
        # @return false otherwise
        def exist?( id )
          job_list.has_key?( id ) unless empty?
        end

        # Clears the job list
        def clear_list
          job_list.clear unless empty?
        end

        # Adds a video joiner job to the job list
        # @param id [string] the job ID
        # @param joiner  [Videojoiner::FFMpeg::Joiner] the joiner job object
        # @return false if the job exists already
        def add_job( id, joiner )
          if exist?( id )
            false
          else
            job_list.store( id, joiner )
          end
        end

        # Removes a video joiner job from the job list
        # @param id [string] the job ID
        # @return false if the job don't exists
        def remove_job( id )
          if exist?( id ) 
            job_list.delete( id )
          else
            false
          end
        end

        # Check that the video sources passed has parameters are valid for the joining process
        # @param video_sources [array] an array with the source videos
        # @return a hash with the source videos, its validation status and size
        def probe_videos( video_sources )
          output = Hash.new
          video_sources.each do |source|
            inspector = RVideo::Inspector.new( :file => "#{source}" ) unless !File.exist?( source )
            if inspector && ( inspector.valid? ) && ( inspector.duration > 0 )
              output.store( source, { status: 'valid', size: File.size( source ) } )
            else
              output.store( source, { status: 'invalid' } )
            end
          end
          output
        end

        # Yields the current object to configure some required parameters
        def configure( &block )
          yield self
        end

        private

        # Return the joiner job list, or generate an empty list if it don't exist already
        # It requires the setting of the config_path parameter previously
        def job_list
          raise ConfigurationError, "Missing configuration: please check Joiner.config_path" unless configured?
          raise ConfigPathError, "Config path not exist" unless Dir.exist?( config_path )
          @job_list ||= Hash.new
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
