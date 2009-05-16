# Extensions to RSPEC's Spec::Runner::Reporter

require 'spec/runner/reporter'

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
      # and set up the superclass' dump 
      # method to run after we're all done
      def initialize_spreadsheet
        @start_time = Time.new
        #at_exit {original_dump}
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
        error = args[1]
        if error
          if ::Spec::Matchers.actual_error
            error.set_backtrace(::Spec::Matchers.actual_error.backtrace) 
          else
            error.set_backtrace(nil) 
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
require 'spec/matchers/raise_error'
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

require 'spec/matchers'
module Spec
  module Matchers
    class << self
      attr_accessor :actual_error
    end
  end
end


require 'spec/runner/formatter/html_formatter'
# Ignore empty backtraces. It would be good
# if we could show a snippet from the code that 
# was called in the test fixture here. Not sure
# how hard that would be. 
#
# Also show exceptions as Yellow and test 
# failures as Red
module Spec
  module Runner
    module Formatter
      class HtmlFormatter < BaseTextFormatter

        def example_failed(example, counter, failure)
          failure.exception.backtrace ? extra = extra_failure_content(failure) : extra = ''
          failure_style = failure.pending_fixed? ? 'pending_fixed' : 'failed'
          @output.puts "    <script type=\"text/javascript\">makeRed('rspec-header');</script>" unless @header_red
          @header_red = true
          @output.puts "    <script type=\"text/javascript\">makeRed(\"example_group_#{example_group_number}\");</script>" unless @example_group_red
          @example_group_red = true
          move_progress
          @output.puts "    <dd class=\"spec #{failure_style}\">"
          @output.puts "      <span class=\"failed_spec_name\">#{h(example.description)}</span>"
          @output.puts "      <div class=\"failure\" id=\"failure_#{counter}\">"
          @output.puts "        <div class=\"message\"><pre>#{h(failure.exception.message)}</pre></div>" unless failure.exception.nil?
          @output.puts "        <div class=\"backtrace\"><pre>#{format_backtrace(failure.exception.backtrace)}</pre></div>" unless failure.exception.nil?
          @output.puts extra unless extra == ""
          @output.puts "      </div>"
          @output.puts "    </dd>"
          @output.flush
        end
        
        def extra_failure_content(failure)
          require 'spec/runner/formatter/snippet_extractor'
          @snippet_extractor ||= SnippetExtractor.new
          "    <pre class=\"ruby\"><code>#{@snippet_extractor.snippet(failure.exception)}</code></pre>"
        end
      end
    end
  end
end


