require 'rasta/bookmark'
require 'rasta/metrics'

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
        return if @bookmark.exceeded_max_records?
        @metrics.reset_page_counts
        @test_fixture = self.dup 
        before_each_worksheet(@oo.default_sheet)
        @oo.records.each do |record|
          before_each_record(record)
          @metrics.reset_record_counts
          @current_record = record
          @test_fixture = self.dup #make a copy so the state is reset every record
          next unless @bookmark.found_record?(record.index)
          break if @bookmark.exceeded_max_records?
          @metrics.inc(:record_count)
          execute_record(record)
          after_each_record(record)
        end
        @test_fixture = self.dup 
        after_each_worksheet(@oo.default_sheet)
      end
      
      def before_each_worksheet(sheet)
        send_record_to_spreadsheet_formatter('before_all')
        try(:before_all)
      end
      def before_each_record(record)
        send_record_to_spreadsheet_formatter(record.name)
        try(:before_each)
      end
      def before_each_cell(cell); end
      def after_each_cell(cell); end
      def after_each_record(record)
        send_record_to_spreadsheet_formatter(record.name)
        try(:after_each)
      end
      def after_each_worksheet(sheet)
        send_record_to_spreadsheet_formatter('after_all')
        try(:after_all)
      end
      
    private 
      # Given a cell that is a method call
      # create an rspec test that can check the 
      # return value and handle any exceptions
      def call_test_fixture_method(cell)
        @metrics.inc(:method_count)
        test_method_name = "#{cell.header}()"
        test_fixture = @test_fixture
        describe "#{@oo.default_sheet}[#{cell.header}]" do 
          include TestCaseHelperMethods
        
          before(:all) do
            @fixture = test_fixture
            @cell = cell.value
            @header = cell.header
            @@actual_value = nil
            # If the cell's value is an exception, parse it out so we can handle properly
            @exception_expected = !(@cell.to_s =~ /^error\s*((?:(?!:\s).)*):?\s*(.*)/).nil?
            if @exception_expected
              @exception = eval($1) if $1 != ''
              @exception_message = $2 if $2 != ''
            end
          end
       
          if test_fixture.pending
            it "#{test_method_name} should match #{cell.value.to_s}" do 
              pending(test_fixture.pending)
            end
          else
            it "#{test_method_name} should match #{cell.value.to_s}" do 
              rspec_test_case
            end
          end
        
          after(:all) do
            @fixture = nil
          end
        end
        run_rspec_test
      end

      def with_each_cell(cell)
        send_record_to_spreadsheet_formatter(cell.name)
        return if cell.empty?
        if pending?(cell)
          @test_fixture.pending = cell.value
        elsif ruby_attribute?(cell)
          set_test_fixture_value(cell)
        elsif ruby_method?(cell)
          call_test_fixture_method(cell)
        else 
          raise "Not sure how to handle cell #{cell.name} - not a method or attribute"
        end
      end
      
      def ruby_method?(x)
        self.respond_to?(x.header) 
      end
      
      def ruby_attribute?(x)
        self.respond_to?(x.header + '=') && self.respond_to?(x.header)
      end
      
      def pending?(x)
        x.header == 'pending'
      end

      def ignore?(x)
        ['comment','description'].include?(x.header) ? true : false
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
      
       
      # Call into rspec to run the current set of tests
      # and then remove the example from the group which
      # if we dont will run test 1 then test 1,2 then test 1,2,3
      # and we'll get duplicate test results accordingly
      def run_rspec_test
         Spec::Runner.options.run_examples
         Spec::Runner.options.remove_example_group(Spec::Runner.options.example_groups[0]) 
      end
      
      def send_record_to_spreadsheet_formatter(x)
        Spec::Runner.options.reporter.record = @oo.default_sheet + '-' + x.to_s
      end

      # Allow access to the current failure count from RSpec
      # which will let us change the tab color based on the test results
      def current_failure_count
        Spec::Runner.options.reporter.failure_count
      end
      
      # Call a method in the test fixture and if it 
      # throws an exception, create an rspec test. 
      def try(method)
        if @test_fixture.methods.include?(method.to_s)
          test_description = "#{@test_fixture.class}#{'[' + @current_record.name + ']' if @current_record} #{method.to_s}()"
          fixture = @test_fixture
          describe test_description do
            it "should not throw an exception" do
               lambda{ fixture.send method }.should_not raise_error
            end
          end
          run_rspec_test
        end  
      end
      
    end

    module TestCaseHelperMethods
      @@actual_value = nil

      def rspec_test_case
        if @exception_expected
          if @exception
            lambda{ @fixture.send @header }.should raise_error(@exception, @exception_message)
          else
            lambda{ @fixture.send @header }.should raise_error
          end
        else
          lambda{ @@actual_value = @fixture.send @header }.should_not raise_error
          if @cell == 'nil'
            expected_value = nil
          else
            expected_value = @cell
          end
          case expected_value
          when /^\s*<=(.+)/
            @@actual_value.should be_less_than_or_equal_to($1.to_f)
          when /^\s*>=(.+)/
            @@actual_value.should be_greater_than_or_equal_to($1.to_f)
          when /^\s*<(.+)/
            @@actual_value.should be_less_than($1.to_f)
          when /^\s*>(.+)/
            @@actual_value.should be_greater_than($1.to_f)
          when Regexp
            @@actual_value.should =~ expected_value
          else
            @@actual_value.should == expected_value
          end
        end
      end
    end

  end  
end 