require 'rasta/fixture/abstract_fixture'
require 'rasta/fixture/rspec_helpers'

module Rasta
  module Fixture
    module RastaFixture 
      include Rasta::Fixture::AbstractFixture
      attr_accessor :pending, :description, :comment, :rasta_options
      
      def execute_worksheet
        before_each_worksheet               
        @oo.records.each do |record|
          before_each_record(record)
          execute_record(record)
          after_each_record(record)
        end
        after_each_worksheet
      end
      
      def execute_record(record)
        record.each do |cell|
          before_each_cell(cell)
          execute_cell(cell)
          after_each_cell(cell)
        end 
      end

      def before_each_worksheet
        @metrics.reset_page_counts
        @bookmark = Rasta::Bookmark.new(@rasta_options)
        @bookmark.page_count += 1
        initial_failure_count = current_failure_count
        return unless @bookmark.found_page?(@oo.default_sheet)
        try(:before_all)
      end
      
      def after_each_worksheet
        try(:after_all)
      end
      
      def before_each_record(record)
        @metrics.reset_record_counts
        @current_record = record
        @metrics.inc(:record_count)
        @test_fixture = self.dup #make a copy so attributes don't bleed between rows
        try(:before_each)
      end
      
      def after_each_record(record)
        try(:after_each)
      end

      def before_each_cell(cell); 
        @metrics.inc(:cell_count)
        next if !@bookmark.found_record?(@metrics.cell_count)
        @bookmark.record_count += 1
        return if @bookmark.exceeded_max_records?
      end
      
      def after_each_cell(cell)
      end
            
      
      def execute_cell(cell)
        send_record_to_rspec_formatter(cell)
        call_test_fixture(cell.header, cell.value)
      end
      
      # The cell is a valid cell if 
      def cell_empty?(header, value)
        (value.nil? || value == '' || header.nil? || header == '') ? true : false
      end
      
      # Check to see if the cell's header is an attribute
      # or a method and call it or raise an error
      def call_test_fixture(header, value)
        return if cell_empty?(header, value)
        if header == 'pending'
          @test_fixture.pending = value
        elsif self.methods.include?(header + '=') 
          execute_set_test_value(header, value)
        else
          # don't specifically check that the method
          # exists so we can allow for things like
          # dynamic methods. An exception still gets thrown
          # so we should be able to handle missing methods
          execute_method(header, value)
        end
      end
      
      def execute_method(header, value)
        before_each_method(header, value)
        execute_test_method(header, value)
        after_each_method(header, value)
      end
      
      # For cell headers detected as test fixture 
      # attributes, set the attribute
      def execute_set_test_value(header, value)
        before_each_test_value(header, value)
        set_test_value(header, value)
        after_each_test_value(header, value)
      end
      
      def set_test_value(header, value)
        @test_fixture.send("#{header}=", value)
      end
      
      def before_each_test_value(header, value)
        @metrics.inc(:attribute_count)
      end
      
      def after_each_test_value(header, value)
      end      
      
      def before_each_method(header, value)
        @metrics.inc(:method_count)
      end

      def after_each_method(header, value)
        run_rspec_test
      end      
      
      # Given a cell that is a method call
      # create an rspec test that can check the 
      # return value and handle any exceptions
      def execute_test_method(header, value)
        test_method_name = "#{header}()"
        test_fixture = @test_fixture
        describe "#{@oo.default_sheet}[#{header}]" do 
          include TestCaseHelperMethods
          
          before(:all) do
            @fixture = test_fixture
            @cell = value
            @header = header
            @@actual_value = nil
            # If the cell's value is an exception, parse it out so we can handle properly
            @exception_expected = !(@cell.to_s =~ /^error\s*((?:(?!:\s).)*):?\s*(.*)/).nil?
            if @exception_expected
              @exception = eval($1) if $1 != ''
              @exception_message = $2 if $2 != ''
            end
          end
         
          if test_fixture.pending
            it "#{test_method_name} should match #{value.to_s}" do 
              pending(test_fixture.pending)
            end
          else
            it "#{test_method_name} should match #{value.to_s}" do 
              run_rspec_test_case
            end
          end
          
          after(:all) do
            @fixture = nil
          end
        end
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

