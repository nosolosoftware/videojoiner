require 'spec_helper'

describe Videojoiner::FFMpeg::Joiner do

  before do
    Videojoiner::FFMpeg::Joiner.configure do |c|
      c.config_path = "/tmp/"
    end
    @joiner = Videojoiner::FFMpeg::Joiner.new( "test", [ "aaa.mp4", "bbb.mp4", "ccc.mp4" ] )
    Videojoiner::FFMpeg::Joiner.add_job( "test", @joiner )
  end

  it "should return false when adding an existent joiner job" do
    Videojoiner::FFMpeg::Joiner.add_job( "test", @joiner ).should be_false
  end

  it "should return false when deleting an unexistent joiner job" do
    Videojoiner::FFMpeg::Joiner.remove_job( "unexistent_job" ).should be_false
  end

  it "should return false when fetching an unexistent joiner job" do
    Videojoiner::FFMpeg::Joiner.fetch( "unexistent_job" ).should be_false
  end
end


