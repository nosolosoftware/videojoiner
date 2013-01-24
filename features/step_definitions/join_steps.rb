Given /^I have a set of correct video files$/ do
  for i in 1..3 do
    FileUtils.copy( "features/support/sample.mp4", "/tmp/#{i}.mp4" )
  end

  @video_routes = [ "/tmp/1.mp4", "/tmp/2.mp4", "/tmp/3.mp4" ]
end

When /^I create the video joiner job with id "(.*?)"$/ do | id |
  @joiner_job = Videojoiner::FFMpeg::Joiner.new( id, @video_routes )
  @joiner_job.create( { filename: "video_root/#{id}_#{Time.now.to_i}" } )
end

When /^the video joiner job has finished$/ do
  wait_for( 5 ){
    @joiner_job.finished?
  }.should be_true
end

Then /^there should be a valid video file$/ do
  File.exist?( @joiner_job.output_file )
  file = RVideo::Inspector.new( :file => @joiner_job.output_file )
  file.should be_valid
end

Then /^it should report all included videos as valid$/ do
  job = Videojoiner::FFMpeg::Joiner.fetch( @joiner_job.id )
  job.video_list.each_value{ |value| value.should == "valid" }
end

Given /^I have a set of invalid videos$/ do
  for i in 1..2 do
    FileUtils.copy( "features/support/sample.mp4", "/tmp/#{i}.mp4" )
  end
  FileUtils.copy( "features/support/unknown_format.mp4", "/tmp/3.mp4" )
  FileUtils.copy( "features/support/zero_duration.mp4", "/tmp/4.mp4" )
  @video_routes = [ "/tmp/1.mp4", "/tmp/2.mp4", "/tmp/3.mp4", "/tmp/4.mp4" ]
end

Then /^it should report that a video from the set is invalid$/ do
  job = Videojoiner::FFMpeg::Joiner.fetch( @joiner_job.id )
  job.video_list.to_s.count( "invalid" ) == 2
end

Then /^it should report that the job creation was unsucessful$/ do
  @status.should be_false
end

When /^I delete the video joiner job with id "(.*?)"$/ do | id |
  @status = @joiner_job.delete
end

Then /^the joiner video job with id "(.*?)" should not exist$/ do | id |
  Videojoiner::FFMpeg::Joiner.exist?( id ).should be_false
end

Then /^it should report that the job deletion was unsucessful$/ do
  @status.should be_false
end
