require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rasta/fixture_runner'

describe 'Class Loader' do
  it 'should load a directory of fixtures' do
    @loader = Rasta::ClassLoader.new(Test::Fixture_dir)
    @loader.load_test_fixtures
    @loader.required_files.should == [File.join(Test::Fixture_dir, 'TestFixture.rb'), File.join(Test::Fixture_dir, 'TestFixture2.rb')]
  end
  it 'should load fixtures from a file' do
    @loader = Rasta::ClassLoader.new(File.join(Test::Fixture_dir, 'TestFixture.rb'))
    @loader.load_test_fixtures 
    @loader.required_files.should == [File.join(Test::Fixture_dir, 'TestFixture.rb')]
  end
end

describe 'Fixture Runnner' do
  before :all do
    @results_dir = File.join(Dir.tmpdir, 'rasta_test_results')
    @runner = Rasta::FixtureRunner.new(:results_path=>@results_dir)
  end
  
  before :each do
    FileUtils.rm_r(@results_dir) if File.directory?(@results_dir)
  end
  
  after :each do
    FileUtils.rm_r(@results_dir) 
  end

  it 'should create a results directory if one does not exist' do
    @runner.prepare_results_directory
    File.directory?(@results_dir).should be_true
    
  end

end


