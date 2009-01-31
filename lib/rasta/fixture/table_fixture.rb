require 'spec'
require 'rasta/fixture/rasta_fixture'
require 'rasta/fixture/rspec_helpers'

module Rasta
  module Fixture
    
    module RastaTableFixture 
      include Rasta::Fixture::BaseFixture
      
      def rasta_table
        @sheet.to_a
      end

      def generate_rspec_tests
        @metrics.reset_page_counts
        initial_failure_count = current_failure_count
        try(:before_all)
        @metrics.inc(:record_count)
        @metrics.inc(:method_count)
        create_rspec_test(@sheet[1][1])
        run_rspec_test
        try(:after_all)
        update_tab_color(current_failure_count > initial_failure_count)
      end
      

      # Given a cell that is a method call
      # create an rspec test that can check the 
      # return value and handle any exceptions
      def create_rspec_test(cell)
         select_output_cell(cell)
        test_method_name = "verify_rasta_table"
        test_fixture = self
        describe "#{@sheet.name}[verify table]" do 
          include TestCaseHelperMethods
          
          before(:all) do
            @fixture = test_fixture
            @cell = nil
            @@actual_value = nil
          end
          
          it "#{test_method_name} should handle exceptions" do
            lambda{ @@actual_value = @fixture.send 'verify_rasta_table' }.should_not raise_error
          end
        end
      end
      
      # Call a method in the test fixture and if it 
      # throws an exception, create an rspec test. This
      # is not for standard tests, but for setup and 
      # teardown tasks that should happen but are not part
      # of the actual test cases. 
      def try(method)
        return if !method
        if methods.include?(method.to_s)
          begin
            self.send method
          rescue SystemExit
            exit
          rescue Interrupt
            exit
          rescue => error_message
            # If the method gets an error, re-raise the error
            # in the context of rspec so the results pick it up
            describe "#{self.class}[#{@current_record.to_s}] #{method.to_s}()" do
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

