#=========================
# CUSTOM MATCHERS
#=========================

Spec::Matchers.define :be_greater_than do |act|
  match do |exp|
    exp > act
  end
end

Spec::Matchers.define :be_greater_than_or_equal_to do |act|
  match do |exp|
    exp >= act
  end
end

Spec::Matchers.define :be_less_than do |act|
  match do |exp|
    exp < act
  end
end

Spec::Matchers.define :be_less_than_or_equal_to do |act|
  match do |exp|
    exp <= act
  end
end

#=========================
# CHANGING TEST EXECUTION
#=========================

# We need to modify the Spec::Runner::Reporter class
# so we can use a custom formatter and pass along cell information
# to the formatter via the reporter 
# (there's no built in way for the examples to pass 
# data into the formatters).
#
# Additionally, we're making a change to the workflow. By default, 
# rspec runs all of the examples at exit. We want to run them at
# the time we read the cell, execture one or more tests, and update that cell.
# Additionally, we don't want to report results after each call to the 
# rspec runner but instead wait until we're totally done. 
module Spec
  module Runner
    class Reporter


      @@started_formatters = false
      
      # Initialize the start time
      def initialize_spreadsheet
        @start_time = Time.new
        at_exit{ dump }
      end
      
      # Call the formatter's method and pass in the reference
      # to the spreadsheet cell so it can use it for updating 
      # the cell contents based on the test result
      def record=(spreadsheet_record)
        formatters.each { |f| f.record=(spreadsheet_record) if f.methods.include?('record=') }
      end
      
      def roo=(roo_reference)
        formatters.each { |f| f.oo=(roo_reference) if f.methods.include?('oo=') }
      end

      # Stub out the dump method and call it
      # after all tests are run
      alias  :original_dump :dump
      def dump; end
      
      # Change so we don't clear the state after each run
      # and don't reset the start time
      alias  :original_start :start
      def start(number_of_examples)
        
        #clear                   [REMOVED so we keep state across tests]
        #@start_time = Time.new  [MOVED to initialize_spreadsheet]
        if !@@started_formatters
          formatters.each{|f| f.start(number_of_examples)} 
          @@started_formatters = true
        end
      end
      
      # Expose the failure count to Rasta
      def failure_count
        @failures.length
      end
      
      alias :old_example_finished :example_finished
      def example_finished(*args)
        error = *args[1]
        if error
          if ::Spec::Matchers.actual_error
            error.set_backtrace(::Spec::Matchers.actual_error.backtrace) 
          else
            error.set_backtrace([]) 
          end
        end
        old_example_finished(*args)
      end
    
    end
  end
end

module Spec
  module Runner
    class Options
      def clear_format_options
        @formatters = []; 
        @format_options = []; 
      end
    end
  end
end

#=========================
# HANDLING EXCEPTIONS
#=========================

# RSpec currently throws an exception for where the test failed in
# the rspec test code. Instead, it's more useful for us to see
# the exception thrown in the proc that is called by rspec
# so we're going to provide a way to get at it 

# After calling the matcher we should store the 
# actual exception (not the rspec exception) for reporting
module Spec
  module Matchers
    class RaiseError 
      alias :old_matches? :matches?
      def matches?(*args)
        old_matches?(*args)
        if @actual_error
          ::Spec::Matchers.actual_error = @actual_error
        else
          ::Spec::Matchers.actual_error = nil
        end
      end
    end
  end
end

# Find a place to store the actal error 
# that the example code can see. 
module Spec
  module Matchers
    class << self
      attr_accessor :actual_error
    end
  end
end