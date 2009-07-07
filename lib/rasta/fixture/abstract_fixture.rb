require 'rasta/fixture/bookmark'
module Rasta
  module Fixture
    module AbstractFixture
       
      def initialize_fixture(roo_reference, bookmark)
        @oo = roo_reference
        @metrics = Rasta::Fixture::Metrics.new
        @bookmark = bookmark
      end
      
      def execute_worksheet
        return unless @bookmark.found_page?(@oo.default_sheet)
        @metrics.reset_page_counts
        before_each_worksheet(@oo.default_sheet)
        @oo.records.each do |record|
          before_each_record(record)
          @metrics.reset_record_counts
          @current_record = record
          @test_fixture = self.dup #make a copy so attributes don't bleed between rows
          next unless @bookmark.found_record?(record.name)
          break if @bookmark.exceeded_max_records?
          @metrics.inc(:record_count)
          execute_record(record)
          after_each_record(record)
        end
        after_each_worksheet(@oo.default_sheet)
      end
      
      def execute_record(record)
        record.each do |cell|
          before_each_cell(cell)
          @metrics.inc(:cell_count)
          execute_cell(cell)
          after_each_cell(cell)
        end 
      end

      def execute_cell(cell)
        before_each_cell(cell)
        with_each_cell(cell)
        after_each_cell(cell)
      end
      
      # actions triggered while parsing the spreadsheet
      def before_each_worksheet(sheet); end
      def before_each_record(record); end
      def before_each_cell(cell); end
      def after_each_cell(cell); end
      def after_each_record(record); end
      def after_each_worksheet(sheet); end
       
      # Call into rspec to run the current set of tests
      # and then remove the example from the group which
      # if we dont will run test 1 then test 1,2 then test 1,2,3
      # and we'll get duplicate test results accordingly
      def run_rspec_test
         Spec::Runner.options.run_examples
         Spec::Runner.options.remove_example_group(Spec::Runner.options.example_groups[0]) 
      end
      
      def send_record_to_spreadsheet_formatter(x)
        Spec::Runner.options.reporter.record = @oo.default_sheet + '-' + x.name
      end

      # Allow access to the current failure count from RSpec
      # which will let us change the tab color based on the test results
      def current_failure_count
        Spec::Runner.options.reporter.failure_count
      end
      
      # Call a method in the test fixture and if it 
      # throws an exception, create an rspec test. 
      def try(method)
        return if !method
        if @test_fixture.methods.include?(method.to_s)
          begin
            @test_fixture.send method
          rescue SystemExit
            exit
          rescue => error_message
            # If the method gets an error, re-raise the error
            # in the context of rspec so the results pick it up
            describe "#{@test_fixture.class}[#{@current_record.name}] #{method.to_s}()" do
              it "should not throw an exception" do
                lambda{raise error_message}.should_not raise_error
              end
            end
            run_rspec_test
          end
        end  
      end
      
    end
  end  
end 