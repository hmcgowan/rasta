require File.join(File.dirname(__FILE__), 'spec_helper')

require 'rasta/fixture_runner'
require 'rasta/fixture/page_fixture'

testfile = File.join(Test::Root_dir, 'examples', 'rasta_fixture.ods')
fixture_path = File.join(Test::Root_dir, 'examples', 'fixtures')


# Change the fixture in use so it does not create RSpec tests
# and reports data we can query about the test run
module Rasta
  module Fixture
    module RastaTestFixture
      include PageFixture
      
      class << self
        def rasta_metrics; @@rasta_metrics; end
        def reset_rasta_metrics; @@rasta_metrics = nil; end
      end

      alias :old_initialize_fixture :initialize_fixture
      def initialize_fixture(*args)
        old_initialize_fixture(*args)
        # collect metrics for each worksheet processed
        @@rasta_metrics ||= Hash.new 
        @@rasta_metrics[@oo.default_sheet] = @metrics
      end

      #stub out rspec tests 
      def call_test_fixture_method(*args);end
      def try(args);end

    end 
  end  
  
  # Stub out the summary results
  class FixtureRunner
    def stop_rspec
      #Spec::Runner.options.reporter.original_dump if Spec::Runner.options
      Spec::Runner.options.clear_format_options
    end
  end  
end 


describe 'rasta_options', :shared => true do
  before :each do
    @options = {:spreadsheets   => [testfile], 
                :fixture_path   => fixture_path, 
                :results_path   => '../rasta_test_results', 
                :extend_fixture => Rasta::Fixture::RastaTestFixture,
                :formatters     => ['SilentFormatter']
                 }
    @test_fixture =  Rasta::Fixture::RastaTestFixture     
  end   
  after :each do
    @test_fixture.reset_rasta_metrics
  end
end

describe 'bookmark from bookmark' do
  it_should_behave_like 'rasta_options'

  it 'Should count the correct number of records when parsing' do 
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 7
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7
  end
  it 'Should be able to start from a tab' do 
    @options.merge!(:bookmark=>'StringFunctions')
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7
  end
  it 'Should be able to do n pages' do 
    @options.merge!(:pages=>2)
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 7
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
  end
  it 'Should be able to do n pages from a tab' do 
    @options.merge!(:pages=>2, :bookmark=>'StringFunctions')
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7
  end
  it 'Should be able to do n records' do 
    @options.merge!(:records=>3)
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 3
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
  end
  it 'Should be able to do n records from a page' do 
    @options.merge!(:records=>3, :bookmark=>'MathFunctions#pending')
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 3
  end
  it 'Should be able to bookmark from a page row' do 
    @options.merge!(:bookmark=>'MathFunctions#pending[5]')
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 4
  end
  it 'Should be able to bookmark from a page row with n records' do 
    @options.merge!(:bookmark=>'MathFunctions#pending[5]', :records=>2)
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 2
  end
  it 'Should be able to bookmark from a page row with n pages' do 
    @options.merge!(:bookmark=>'MathFunctions[5]', :pages=>2)
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 4
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
  end
  it 'Should be able to bookmark from a page column' do 
    @options.merge!(:bookmark=>'StringFunctions[D]')
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 1
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7 
  end
  it 'Should be able to bookmark from a page column with n records' do 
    @options.merge!(:bookmark=>'StringFunctions[D]', :records=>3)
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 1
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 2 
  end
  it 'Should be able to bookmark from a page column with n pages' do 
    @options.merge!(:bookmark=>'StringFunctions[D]', :pages=>1)
    Rasta::FixtureRunner.new(@options).execute
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 1
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
   end
   it 'Should fail gracefully when the bookmark page is invalid' do 
     @options.merge!(:bookmark=>'MissingPage')
     lambda{ Rasta::FixtureRunner.new(@options).execute }.should raise_error
   end
   it 'Should allow user to specify required files' do 
     @options.merge!(:require=>[File.join(fixture_path, 'MathFunctions'),File.join(fixture_path, 'StringFunctions')])
     @options.delete(:fixture_path)
     lambda{ Rasta::FixtureRunner.new(@options).execute }.should_not raise_error
   end
end    
