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
    @runner = Rasta::FixtureRunner.new({})
  end
  
  it 'should create a results directory if one does not exist' do
    @results_dir = File.join(Dir.tmpdir, 'this_directory_does_not_exist')
    @runner.create_results_directory(@results_dir)
    File.directory?(@results_dir).should be_true
  end

  it 'should empty an existing results directory' do
    @results_dir = File.join(Dir.tmpdir, 'this_directory_does_not_exist')
    @file_in_results_dir = File.join(@results_dir, 'some_file')
    FileUtils.mkdir_p(@results_dir) 
    FileUtils.touch(@file_in_results_dir)
    @runner.create_results_directory(@results_dir)
    File.directory?(@results_dir).should be_true
    File.exists?(@file_in_results_dir).should be_false
  end
  
  after :each do
    FileUtils.rm_r(@results_dir) 
  end
end


