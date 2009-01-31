require 'rasta/fixture/base_fixture'

module Rasta
  module Fixture
    module RastaFixture 
      include Rasta::Fixture::BaseFixture
      attr_accessor :pending, :description
      
      def generate_rspec_tests
        @metrics.reset_page_counts
        @test_fixture = self        
        initial_failure_count = current_failure_count
        try(:before_all)
        
        records(@oo).each do |record|
          @metrics.reset_record_counts
          @current_record = record
          @metrics.inc(:record_count)
          @test_fixture = self.dup #make a copy so attributes don't bleed between rows
          try(:before_each)
          record.headers.each do |header|
            call_test_fixture(header, record[header])
          end 
          try(:after_each)
          @test_fixture = self
        end
    
        try(:after_all)
      end
      
      # Check to see if the cell's header is an attribute
      # or a method and call it or raise an error
      def call_test_fixture(header, value)
        return if value.nil? || value == '' || header.nil? || header == ''
        if header == 'pending'
          @test_fixture.pending = value
        elsif self.methods.include?(header + '=') 
          call_fixture_attribute(header, value)
        else
          # don't specifically check that the method
          # exists so we can allow for things like
          # dynamic methods. An exception still gets thrown
          # so we should be able to handle missing methods
          call_fixture_method(header, value)
        end
      end
      
      # For cell headers detected as test fixture 
      # attributes, set the attribute
      def call_fixture_attribute(header, value)
        @metrics.inc(:attribute_count)
        @test_fixture.send("#{header}=", value)
      end
      
      # For cell headers detected as test fixture 
      # methods, call the method and run the rspec test
      def call_fixture_method(header, value)
        @metrics.inc(:method_count)
        create_rspec_test(header, value)
        run_rspec_test
      end
      
      # Given a cell that is a method call
      # create an rspec test that can check the 
      # return value and handle any exceptions
      def create_rspec_test(header, value)
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
            it "#{test_method_name} should == #{value.to_s}" do 
              pending(test_fixture.pending)
            end
          else
            it "#{test_method_name} should == #{value.to_s}" do 
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
            describe "#{@test_fixture.class}[#{@current_record.to_s}] #{method.to_s}()" do
              it "should not throw an exception" do
                lambda{raise error_message}.should_not raise_error
              end
            end
            run_rspec_test
          end
        end  
      end
      
      module TestCaseHelperMethods
        @@actual_value = nil
        
        def run_rspec_test_case
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
            when /^(<=|>=|>|<)(.+)/  
              eval("@@actual_value.should #{$1} #{$2}")
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
end

