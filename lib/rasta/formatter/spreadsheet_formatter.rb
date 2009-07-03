# TODO: put name of spreadsheet on the page
# and think about how to handle multiple spreadsheets
#
# handle xslt paths
# put tabber back into xsl
# make write use libxml-ruby and not print to file
# need to parse for spreadsheet name if Google

Resource_dir = File.join(File.dirname(__FILE__), '..', 'resources')
require 'spec/runner/formatter/base_formatter'
require 'xml'
require 'xslt'

module Spec
  module Runner
    module Formatter
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseTextFormatter
        attr_accessor :oo, :record
        
        # Store a reference to the spreadsheet record 
        # so we can update the associated cell in the output
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
        
        def example_passed(example)
           xml_cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           xml_cell['class'] = 'result'
           xml_cell['status'] = 'passed'
           title = @record + ': ' + example.description
           add_test_summary_item(title, 'passed')
           save_xml
        end

        def example_failed(example, counter, failure)
           xml_cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           xml_cell['class'] = 'result'
           xml_cell['status'] = failure_type(failure)
           add_test_detail(xml_cell, failure_message(failure))
           title = @record + ': ' + example.description
           exception = failure if failure.exception.backtrace
           add_test_summary_item(title, failure_type(failure), failure_message(failure), exception)
           save_xml
        end
        
        def example_pending(example, message)
           xml_cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           xml_cell['class'] = 'result'
           xml_cell['status'] = 'pending'
           title = @record + ': ' + example.description
           add_test_summary_item(title, 'pending', message)
           save_xml
        end

        # Stub out these methods because we don't need them
        def dump_failure(*args); end
        def dump_pending(*args); end
        
        # Update the totals on the Summary tab
        def dump_summary(duration, example_count, failure_count, pending_count)
          xml_totals = @doc.find("/spreadsheet/summary/totals")[0]
          xml_totals << xml_duration = XML::Node.new('duration')
          xml_duration << duration
          xml_totals << xml_test_count = XML::Node.new('tests')
          xml_test_count << example_count
          xml_totals << xml_failure_count = XML::Node.new('failures')
          xml_failure_count << failure_count
          xml_totals << xml_pending_count = XML::Node.new('pending')
          xml_pending_count << pending_count
          save_xml
        end

        def add_test_summary_item (title, classname, message=nil, exception=nil)
          xml_summary = @doc.find("/spreadsheet/summary")[0]
          xml_summary <<  xml_item = XML::Node.new('item')
          xml_item['class'] = classname
          xml_item << xml_title = XML::Node.new('title')
          xml_title << title
          if message
            xml_item << xml_description = XML::Node.new('description')
            xml_description << message
            if exception
              xml_item << xml_exception = XML::Node.new('exception')
              add_code_snippet(xml_exception, exception) 
            end
          end  
        end
        
        def add_test_detail(xml_cell, text)
          xml_cell << xml_detail = XML::Node.new('detail')
          xml_detail << text
        end
          
        def add_code_snippet(xml_exception, failure)
          require 'spec/runner/formatter/snippet_extractor'
          @snippet_extractor ||= SnippetExtractor.new
          (raw_code, linenum) = @snippet_extractor.snippet_for(failure.exception.backtrace[0])
          raw_code.split("\n").each_with_index do |line, l|
            line = "#{l + linenum - 2}: " + line
            xml_exception << xml_line = XML::Node.new('line') 
            if l == 2
              xml_line['class'] = 'offending' 
            else
              xml_line['class'] = 'linenum'
            end
            xml_line << line.strip
          end
        end
        
        def failure_message(failure)
          failure.exception.backtrace ? failure.exception.message + "\n" + failure.exception.backtrace.join("\n") : failure.exception.message 
        end

        def failure_type(failure)
          failure.exception.backtrace ? 'exception' : 'failed'
        end

        def xml_header
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?><spreadsheet><summary filename=\"#{File.basename(@oo.filename)}\"><totals></totals></summary></spreadsheet>"
        end

        def add_xml_worksheets
          current_sheet = @oo.default_sheet
          @oo.sheets.each do |sheet|
            @oo.default_sheet = sheet
            next unless @oo.first_column(sheet) #skip empty worksheets
            add_xml_worksheet
          end
          @oo.default_sheet = current_sheet
        end
        
        def add_xml_worksheet
          sheet_name = @oo.default_sheet
          linenumber = @oo.first_row(sheet_name) 
          xml_spreadsheet = @doc.find('/spreadsheet')[0]
          xml_spreadsheet << xml_sheet = XML::Node.new('sheet')
          xml_sheet['id'] = sheet_name
          add_xml_worksheet_column_header(xml_sheet)
          @oo.first_row.upto(@oo.last_row) do |row_name|
            xml_sheet << xml_row = XML::Node.new('row')
            xml_row << xml_cell = XML::Node.new('cell')
            xml_cell['class'] = 'row-index'
            xml_cell << xml_value = XML::Node.new('value')
            xml_value << linenumber.to_s
            linenumber += 1
            add_xml_worksheet_cell_values(xml_row, row_name)
          end
        end

        def add_xml_worksheet_cell_values(xml_row, row_name)
          sheet_name = @oo.default_sheet
          records = @oo.records(sheet_name)
          @oo.first_column(sheet_name).upto(@oo.last_column(sheet_name)) do |col_name|
            xml_row << xml_cell = XML::Node.new('cell')
            if (records.type == :column && col_name == records.header_index) || records.type == :row && row_name == records.header_index
              xml_cell['class'] = 'header'
            else
              xml_cell['id'] = "#{GenericSpreadsheet.number_to_letter(col_name)}#{row_name}"
              xml_cell['status'] = 'not_run' 
            end
            xml_cell << xml_value = XML::Node.new('value')
            val = @oo.cell(row_name,col_name).to_s
            xml_value << val unless val == ''
          end
        end
                
        def add_xml_worksheet_column_header(xml_sheet)
          sheet_name = @oo.default_sheet
          xml_sheet << xml_row = XML::Node.new('row')
          xml_row << XML::Node.new('cell')
          (@oo.first_column(sheet_name)..@oo.last_column(sheet_name)).each do |col|
            xml_row << xml_cell = XML::Node.new('cell')
            xml_cell['class'] = 'column-index'
            xml_cell << xml_value = XML::Node.new('value')
            xml_value << GenericSpreadsheet.number_to_letter(col)
          end
        end
        
      end        
    end
  end
end
