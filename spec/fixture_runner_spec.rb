require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rasta/fixture_runner'

describe 'Fixture Runnner' do

  before :all do
    @results_dir = File.join(Dir.tmpdir, 'rasta_test_results')
  end
  
  before :each do
    FileUtils.rm_r(@results_dir) if File.directory?(@results_dir)
  end
  
  after :each do
    FileUtils.rm_r(@results_dir) 
  end

  it 'should create a results directory if one does not exist' do
    @runner = Rasta::FixtureRunner.new(:results_path=>@results_dir)
    @runner.prepare_results_directory
    File.directory?(@results_dir).should be_true
  end

end


