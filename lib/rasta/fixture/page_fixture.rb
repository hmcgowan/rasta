require 'spec'
require 'rasta/fixture/rasta_fixture'
require 'rasta/fixture/rspec_helpers'

module Rasta
  module Fixture
    
    module RastaPageFixture 
      include Rasta::Fixture::AbstractFixture
      
      class RastaAttributes
        attr_reader :keywords
          def initialize
            @keywords = []
          end
          # Create singleton methods to store 
          # Rasta keywords and values
          def define_keyword(name)
            name = name.to_s.sub(/=$/,'').to_sym
            @keywords << name unless @keywords.index(name)
            return if methods.include?(name)
            sing = class << self; self; end
            sing.class_eval "def #{name}; @#{name}; end"
            sing.class_eval "def #{name}=(x); @#{name}=x; end"
            return true
          end
          
          alias :old_respond_to? :respond_to?
          def respond_to? (method, include_private=false)
            old_respond_to?(method.to_sym, include_private) || 
            define_keyword(method)
          end
          alias :old_method_missing :method_missing
          def method_missing(method, *args)
            define_keyword(method)
            send(method.to_sym, *args)
          end
      end  
        
      def rasta
        @spreadsheet_attributes
      end

      def execute_worksheet
        @metrics.reset_page_counts
        initial_failure_count = current_failure_count
        try(:before_all)
        # Store the state of the default attributes
        # because we'll clear them for each row. 
        @oo.default_sheet.each do |record|
          @metrics.reset_record_counts
          @current_record = record
          @metrics.inc(:record_count)
          @spreadsheet_attributes = RastaAttributes.new
          @spreadsheet_attributes.define_keyword(:comment)
          @spreadsheet_attributes.define_keyword(:pending)
          try(:before_each)
          record.each do |cell|
            call_test_fixture(cell)
          end 
          try(:after_each)
        end
        try(:after_all)
        
        update_tab_color(current_failure_count > initial_failure_count)
      end
      
      
      # Check to see if the cell's header is an attribute
      # or a method and call it or raise an error
      def call_test_fixture(cell)
        name = cell.header
        return if cell.value.nil? || cell.header.nil?
        if cell.header == 'pending'
          rasta.pending = cell.value
        elsif cell.header == 'comment'
          rasta.comment = cell.value
        elsif self.methods.include?(name + '=') 
          call_fixture_attribute(name, cell.value)
        else
          # don't specifically check that the method
          # exists so we can allow for things like
          # dynamic methods. An exception still gets thrown
          # so we should be able to handle missing methods
          call_fixture_method(cell)
        end
      end
      
      def call_fixture_attribute(name, value)
        @metrics.inc(:attribute_count)
        rasta.define_keyword(name)
        instance_eval("rasta.#{name}= value")
      end
      
      # For cell headers detected as test fixture 
      # methods, call the method and run the rspec test
      def call_fixture_method(cell)
        @metrics.inc(:method_count)
        create_rspec_test(cell)
        run_rspec_test
      end
      
      # Given a cell that is a method call
      # create an rspec test that can check the 
      # return value and handle any exceptions
      def create_rspec_test(cell)
        select_output_cell(cell)
        test_method_name = "#{cell.header}()"
        test_fixture = self
        describe "#{cell.sheet.name}[#{cell.name}]" do 
          include TestCaseHelperMethods
          
          before(:all) do
            @fixture = test_fixture
            @cell = cell
            @@actual_value = nil
            # If the cell's value is an exception, parse it out so we can handle properly
            @exception_expected = !(@cell.value.to_s =~ /^error\s*((?:(?!:\s).)*):?\s*(.*)/).nil?
            if @exception_expected
              @exception = eval($1) if $1 != ''
              @exception_message = $2 if $2 != ''
            end
          end
          
          it "#{test_method_name} should handle exceptions" do
            pending(@fixture.rasta.pending) if @fixture.rasta.pending
            check_for_errors
          end
          it "#{test_method_name} should == #{cell.value.to_s}" do 
            pending(@fixture.rasta.pending) if @fixture.rasta.pending
            check_test_result
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

