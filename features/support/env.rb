require 'simplecov'

SimpleCov.start do
  add_filter 'lib/videojoiner/rvideo_patch.rb'
  add_filter 'features/'
end

$LOAD_PATH << File.expand_path( '../../../lib/', __FILE__ )
$LOAD_PATH << File.expand_path( '../', __FILE__ )

require 'bundler'
require 'wait_for'
require 'videojoiner'
require 'rspec/expectations'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

Videojoiner::FFMpeg::Joiner.configure do |c|
  c.config_path = "/tmp/"
end
