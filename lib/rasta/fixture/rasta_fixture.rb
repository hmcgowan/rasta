require 'rasta/fixture/abstract_fixture'
require 'rasta/fixture/rspec_helpers'

module Rasta
  module Fixture
    module RastaFixture 
      include Rasta::Fixture::AbstractFixture
      attr_accessor :pending, :description, :comment

      def before_each_worksheet(sheet)
        try(:before_all)
      end
      
      def before_each_record(record)
        try(:before_each)
      end

      def after_each_record(record)
        try(:after_each)
      end

      def after_each_worksheet(sheet)
        try(:after_all)
      end
      
      def with_each_cell(cell)
        send_record_to_spreadsheet_formatter(cell)
        return if cell.empty?
        if cell.header == 'pending'
          @test_fixture.pending = cell.value
        elsif self.methods.include?(cell.header + '=') 
          @metrics.inc(:attribute_count)
          set_test_fixture_value(cell)
        else
          @metrics.inc(:method_count)
          call_test_fixture_method(cell)
          run_rspec_test
        end
      end
      
      def set_test_fixture_value(cell)
        @test_fixture.send("#{cell.header}=", cell.value)
      end
      
      # Given a cell that is a method call
      # create an rspec test that can check the 
      # return value and handle any exceptions
      def call_test_fixture_method(cell)
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
      end
      
    end 
  end  
end

