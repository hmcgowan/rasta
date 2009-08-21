require File.join(File.dirname(__FILE__), 'spec_helper')

require 'rasta'
testfile = File.join(Test::Root_dir, 'examples', 'rasta_fixture.ods')
fixture_path = File.join(Test::Root_dir, 'examples', 'fixtures')

require 'rasta/fixture/page_fixture'
#require 'rasta/fixture/rspec_helpers'


# Change the fixture in use so it does not create RSpec tests
# and reports data we can query about the test run
module Rasta
  module Fixture
    module RastaTestFixture
      include RastaPageFixture
      
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
      def call_test_fixture_method(cell);end

    end 
  end  
end 

describe 'rasta_options', :shared => true do
  before :all do
    @options = {:spreadsheet    => testfile, 
                :fixture_path   => fixture_path, 
                :results_path   => '../rasta_test_results', 
                :extend_fixture => Rasta::Fixture::RastaTestFixture,
                 }
    @test_fixture =  Rasta::Fixture::RastaTestFixture     
  end   
  after :each do
    @test_fixture.reset_rasta_metrics
  end
end

describe 'continue from bookmark' do
  it_should_behave_like 'rasta_options'

  it 'Should count the correct number of records when parsing' do 
    Rasta::SpreadsheetRunner.new.execute(@options) 
    @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 7
    @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
    @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7
  end
   it 'Should be able to start from a tab' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:continue=>'StringFunctions')) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7
    end
    it 'Should be able to do n pages' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:pages=>2)) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 7
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
    end
    it 'Should be able to do n pages from a tab' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:pages=>2, :continue=>'StringFunctions')) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7
    end
    it 'Should be able to do n records' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:records=>3)) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 3
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
    end
    it 'Should be able to do n records from a page' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:records=>3, :continue=>'MathFunctions#pending')) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 3
    end
    it 'Should be able to continue from a page row' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:continue=>'MathFunctions#pending[5]')) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 4
    end
    it 'Should be able to continue from a page row with n records' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:continue=>'MathFunctions#pending[5]', :records=>2)) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 2
    end
    it 'Should be able to continue from a page row with n pages' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:continue=>'MathFunctions[5]', :pages=>2)) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 4
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 3
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
    end
    it 'Should be able to continue from a page column' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:continue=>'StringFunctions[D]')) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 1
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 7 
    end
    it 'Should be able to continue from a page column with n records' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:continue=>'StringFunctions[D]', :records=>3)) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 1
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 2 
    end
    it 'Should be able to continue from a page column with n pages' do 
      Rasta::SpreadsheetRunner.new.execute(@options.merge(:continue=>'StringFunctions[D]', :pages=>1)) 
      @test_fixture.rasta_metrics['MathFunctions'].record_count.should == 0
      @test_fixture.rasta_metrics['StringFunctions'].record_count.should == 1
      @test_fixture.rasta_metrics['MathFunctions#pending'].record_count.should == 0
     end
end    
