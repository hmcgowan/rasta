# TODO: put name of spreadsheet on the page
# and think about how to handle multiple spreadsheets
#
# handle xslt paths
# put tabber back into xsl
# make write use libxml-ruby and not print to file
#

Resource_dir = File.join(File.dirname(__FILE__), '..', 'resources')
require 'spec/runner/formatter/base_formatter'
require 'xml'
require 'xslt'

module Spec
  module Runner
    module Formatter
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseTextFormatter
        attr_accessor :oo, :record
        
        def record=(x)
          @record = x
          (@sheet, @cell) = @record.split('-')
        end
        
        def start(example_count)
          @example_count = example_count
          @total_count = 0
          @total_passed = 0
          @total_failed = 0
          @total_exception = 0
          @total_pending = 0
          @output.puts xml_header
          @output.flush
          XML.indent_tree_output = true
          XML.default_tree_indent_string = '  '
          parser = XML::Parser.file(@output.path)
          @doc = parser.parse
          add_xml_worksheets
          save_xml
        end
        
        def close
          # Create a new XSL Transform
          stylesheet_doc = XML::Document.file(File.join(Resource_dir, 'spreadsheet.xsl'))
          stylesheet = LibXSLT::XSLT::Stylesheet.new(stylesheet_doc)

          # Transform the xml document
          transform = stylesheet.apply(@doc, {:root => "ROOT", :back => "BACK"})
          parser = XML::Parser.document(transform)
          @doc = parser.parse
          save_xml(@output.path.gsub('xml','html'))
        end
        
        
        def save_xml(filename = @output.path)
          @doc.save(filename, :indent => true, :encoding => XML::Encoding::UTF_8)
        end
        
        def update_totals(name, value)
          # @total_count += 1
          # @doc.find("//td[@class='total-count']")[0].content = @total_count.to_s
          # @doc.find("//td[@class='#{name}']")[0].content = value.to_s
        end  
          
        def update_passed_counts
          update_totals('total-passed', @total_passed += 1)
        end

        def update_failed_counts
          update_totals('total-failed', @total_failed += 1)
        end
        
        def update_pending_counts
          update_totals('total-pending', @total_pending += 1)
        end

        def example_passed(example)
           update_passed_counts
           cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           cell['class'] = 'result'
           cell['status'] = 'passed'
           save_xml
        end

        def example_failed(example, counter, failure)
           update_failed_counts
           cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           cell['class'] = 'result'
           cell['status'] = failure_type(failure)
           add_test_failure_summary(example, failure)
           add_test_failure_tooltip(cell, failure)
           save_xml
        end
        
        def example_pending(example, message)
           update_pending_counts
           cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           cell['class'] = 'result'
           cell['status'] = 'pending'
           add_test_pending_summary(example, message)
           save_xml
        end

        # Stub out these methods because we don't need them
        def dump_failure(*args); end
        def dump_summary(*args); end
        def dump_pending(*args); end
    
        def add_test_failure_tooltip(cell, failure)
          # cell << span = XML::Node.new('span')
          # span << pre = XML::Node.new('pre')
          # pre << @record + "\n" + failure_message(failure)
        end
    
        def add_test_pending_summary (example, message)
          # summary = @doc.find("//div[@class='summary-errors']")[0] 
          # summary << header = XML::Node.new('div')
          # header['class'] = 'error-pending-header'
          # header << @record + ': ' + example.description
          # summary << detail = XML::Node.new('div')
          # detail['class'] = 'error-pending-detail'
          # detail << pre = XML::Node.new('pre')
          # pre << message
        end

        def add_test_failure_summary (example, failure)
          # summary = @doc.find("//div[@class='summary-errors']")[0] 
          # summary << header = XML::Node.new('div')
          # header['class'] = 'error-' + failure_type(failure) + '-header'
          # header << @record + ': ' + example.description
          # summary << detail = XML::Node.new('div')
          # detail['class'] = 'error-' + failure_type(failure) + '-detail'
          # detail << pre = XML::Node.new('pre')
          # pre << failure_message(failure)
          # if failure.exception.backtrace
          #   summary << exception = XML::Node.new('div')
          #   exception['class'] = 'error-failed-exception'
          #   exception << code_snippet(failure) 
          # end  
        end
        
        def code_snippet(failure)
          require 'spec/runner/formatter/snippet_extractor'
          @snippet_extractor ||= SnippetExtractor.new
          pre = XML::Node.new('pre') 
          pre['class'] = 'ruby'
          pre << code = XML::Node.new('code') 
          (raw_code, linenum) = @snippet_extractor.snippet_for(failure.exception.backtrace[0])
          raw_code.split("\n").each_with_index do |line, l|
            line = "#{l + linenum - 2}: " + line
            code << line_p = XML::Node.new('p') 
            if l == 2
             line_p['class'] = 'offending' 
            else
              line_p['class'] = 'linenum'
            end
            code << line
          end
          pre
        end
        
        def failure_message(failure)
          failure.exception.backtrace ? failure.exception.message + "\n" + failure.exception.backtrace.join("\n") : failure.exception.message 
        end

        def failure_type(failure)
          failure.exception.backtrace ? 'exception' : 'failed'
        end

        def html_summary_tab
          @oo.info =~ /File: (\S+)/
          spreadsheet_name = $1 || 'Google Spreadsheet'
          summary = <<-EOS
                      <div class="tabbertab">
                        <div class="summary-counts">
                          <h2>Summary</h2>
                          <table class="summary" summary ="Summary of test results">
                          <tr><td class="summary-title">Filename</td><td class="summary-detail-text">#{spreadsheet_name}</td></tr>
                          <tr><td class="summary-title">Tests Run</td><td class="total-count">0</td></tr>
                          <tr><td class="summary-title">Passed</td><td class="total-passed">0</td></tr>
                          <tr><td class="summary-title">Failed</td><td class="total-failed">0</td></tr>
                          <tr><td class="summary-title">Pending</td><td class="total-pending">0</td></tr>
                          <tr><td class="summary-title">Execution Time</td><td class="total-time">0</td></tr>
                          </table>
                        </div>
                        <br><br>
                      </div>
                    EOS
        end

        def html_errors_tab
          <<-EOS
              <div class="tabbertab">
                <div class="errors">
                  <h2>Errors</h2>
                  <div class="summary-errors"/>
                </div>
              </div>
            EOS
        end
        
        def xml_header
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?><spreadsheet/>"
        end
        
#        xsl_filename = File.join(Resource_dir,'spreadsheet.xsl')
#        <?xml-stylesheet type="text/xsl" href="spreadsheet.xsl"?>
        
        def add_xml_worksheets
          current_sheet = @oo.default_sheet
          @oo.sheets.each do |sheet|
            @oo.default_sheet = sheet
            add_xml_worksheet
          end
          @oo.default_sheet = current_sheet
        end
        
        def add_xml_worksheet
          sheet_name = @oo.default_sheet
          linenumber = @oo.first_row(sheet_name) 
          spreadsheet = @doc.find('/spreadsheet')[0]
          spreadsheet << sheet = XML::Node.new('sheet')
          sheet['id'] = sheet_name
          add_sheet_column_header(sheet)
          @oo.first_row.upto(@oo.last_row) do |row_name|
            sheet << row = XML::Node.new('row')
            row << cell = XML::Node.new('cell')
            cell['class'] = 'row-index'
            cell << linenumber.to_s
            linenumber += 1
            add_row_cell_values(row, row_name)
          end
        end

        def add_row_cell_values(row, row_name)
          sheet_name = @oo.default_sheet
          records = @oo.records(sheet_name)
          @oo.first_column(sheet_name).upto(@oo.last_column(sheet_name)) do |col_name|
            row << cell = XML::Node.new('cell')
            if (records.type == :column && col_name == records.header_index) || records.type == :row && row_name == records.header_index
              cell['class'] = 'header'
            else
              cell['id'] = "#{GenericSpreadsheet.number_to_letter(col_name)}#{row_name}"
              cell['status'] = 'not_run' 
            end
            value = @oo.cell(row_name,col_name).to_s
            cell << value unless value == ''
          end
        end
                
        def add_sheet_column_header(sheet)
          sheet_name = @oo.default_sheet
          sheet << row = XML::Node.new('row')
          row << XML::Node.new('cell')
          (@oo.first_column(sheet_name)..@oo.last_column(sheet_name)).each do |col|
            row << cell = XML::Node.new('cell')
            cell['class'] = 'column-index'
            cell << GenericSpreadsheet.number_to_letter(col)
          end
        end
        
      end        
    end
  end
end
