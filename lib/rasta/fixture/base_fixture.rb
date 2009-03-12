module Rasta
  module Fixture
    module BaseFixture
      include Rasta::Spreadsheet
      include Rasta::Fixture::Metrics
       
      def initialize_test_fixture(roo_reference, options)
        @oo = roo_reference
        @options = options
        @metrics = Counter.new
      end
       
      # Call into rspec to run the current set of tests
      # and then remove the example from the group which
      # if we dont will run test 1 then test 1,2 then test 1,2,3
      # and we'll get duplicate test results accordingly
      def run_rspec_test
         Spec::Runner.options.run_examples
         Spec::Runner.options.remove_example_group(Spec::Runner.options.example_groups[0]) 
      end
      
      def current_rspec_record(x)
        Spec::Runner.options.reporter.record = x
      end

      # Allow access to the current failure count from RSpec
      # which will let us change the tab color based on the test results
      def current_failure_count
        Spec::Runner.options.reporter.failure_count
      end
      
#      def select_output_cell(c, f)
#        Spec::Runner.options.reporter.set_current_spreadsheet_cell(c,f)
#      end
      
      # Iterate over spreadsheet cells, create the
      # test fixtures and call your test. Generally
      # you will need to iterate over the spreadsheet
      # cells and once you have the information you need
      # to actually run the rspec test you should 
      # use:
      #   select_output_cell(cell)
      #      This tells the reporter which spreadsheet
      #      cell should get the results
      #   create_rspec_test(test_fixture, cell)
      #      This is a method you create which will create
      #      rspec testcase(s) based on the inputs
      #   run_rspec_test
      #      This will run the test set up by create_test
      def generate_rspec_tests
      end
      
      # This is the guts of the rspec test you want to call
      # so for example something like 
      #
      # describe 'test' do 
      #   before(:all) do
      #   end
      #   it "testcase 1" do
      #   end
      #   it "testcase 2" do
      #   end
      #   ... etc ...
      #   after(:all) do
      #   end
      # end
      def create_rspec_test(args)
      end 
      
      # This is called by the fixture before any test 
      # is run on the worksheet so you can perform any 
      # setup needed
      #def before_all
      #end
      
      # This method is called before each set of tests
      # typically a row or column of tests or potentially
      # before each cell, depending on the fixture 
      #def before_each
      #end
      
      # This method is called after each set of tests
      # typically a row or column of tests or potentially
      # after each cell, depending on the fixture 
      #def after_each
      #end
      
      # This is called by the fixture after all tests
      # are run on the worksheet so you can perform any 
      # teardown needed
      #def after_all
      #end

    end
  end  
end 