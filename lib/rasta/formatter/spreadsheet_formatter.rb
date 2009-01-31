require 'spec/runner/formatter/base_formatter'
module Spec
  module Runner
    module Formatter
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseFormatter
        
        def initialize(*args)
          @@results ||= {}
          super(*args)
        end
        
        def cell=(x = [])
          @cell = x
        end
        def fixture(x)
          @fixture = x
        end
        def example_failed(example, counter, failure)
          @@results[@cell] = :fail
          @fixture.write_html(@@results) if @fixture
          
#          if @cell 
#            failure.exception.backtrace ? @cell.color = YELLOW : @cell.color = RED
#            comment = "method: " + @cell.header + "()\n"
#            comment += failure.exception.message.gsub(/,\s+/,",\n")  
#            comment += "\n" + failure.exception.backtrace.join("\n") if failure.exception.backtrace
#            @cell.comment = comment
#          end
        end
        
        def example_passed(example)
          @@results[@cell] = :fail
          @fixture.write_html(@@results) if @fixture
        end

       

      end        
    end
  end
end