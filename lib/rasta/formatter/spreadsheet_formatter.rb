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
           cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           cell['class'] = 'result'
           cell['status'] = 'passed'
           save_xml
        end

        def example_failed(example, counter, failure)
           xml_cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           xml_cell['class'] = 'result'
           xml_cell['status'] = failure_type(failure)
           add_test_detail(xml_cell, failure_message(failure))
           title = @record + ': ' + example.description
           add_test_failure_summary(title, failure)
           save_xml
        end
        
        def example_pending(example, message)
           xml_cell = @doc.find("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")[0]
           xml_cell['class'] = 'result'
           xml_cell['status'] = 'pending'
           title = @record + ': ' + example.description
           add_test_pending_summary(title, message)
           save_xml
        end

        # Stub out these methods because we don't need them
        def dump_failure(*args); end
        def dump_pending(*args); end
        
        def dump_summary(duration, example_count, failure_count, pending_count)
          xml_totals = @doc.find("/spreadsheet/summary/totals")[0]
          xml_totals << xml_test_count = XML::Node.new('tests')
          xml_test_count << example_count
          xml_totals << xml_failure_count = XML::Node.new('failures')
          xml_failure_count << failure_count
          xml_totals << xml_pending_count = XML::Node.new('pending')
          xml_pending_count << pending_count
          xml_totals << xml_duration = XML::Node.new('duration')
          xml_duration << duration
          save_xml
        end
    
        def add_test_detail(cell, text)
          cell << detail = XML::Node.new('detail')
          detail << text
        end
          
        def add_test_pending_summary (title, message)
          xml_summary = @doc.find("/spreadsheet/summary")[0]
          xml_summary <<  xml_item = XML::Node.new('item')
          xml_item['class'] = 'pending'
          xml_item << xml_title = XML::Node.new('title')
          xml_title << title
          xml_item << xml_description = XML::Node.new('description')
          xml_description << message
        end

        def add_test_failure_summary (title, failure)
          xml_summary = @doc.find("/spreadsheet/summary")[0]
          xml_summary <<  xml_item = XML::Node.new('item')
          xml_item['class'] = failure_type(failure)
          xml_item << xml_title = XML::Node.new('title')
          xml_title << title
          xml_item << xml_description = XML::Node.new('description')
          xml_description << failure_message(failure)
          if failure.exception.backtrace
            xml_item << xml_exception = XML::Node.new('exception')
            add_code_snippet(xml_exception, failure) 
          end
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
          add_xml_worksheet_column_header(sheet)
          @oo.first_row.upto(@oo.last_row) do |row_name|
            sheet << row = XML::Node.new('row')
            row << cell = XML::Node.new('cell')
            cell['class'] = 'row-index'
            cell << value = XML::Node.new('value')
            value << linenumber.to_s
            linenumber += 1
            add_xml_worksheet_cell_values(row, row_name)
          end
        end

        def add_xml_worksheet_cell_values(row, row_name)
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
            cell << value = XML::Node.new('value')
            v = @oo.cell(row_name,col_name).to_s
            value << v unless v == ''
          end
        end
                
        def add_xml_worksheet_column_header(sheet)
          sheet_name = @oo.default_sheet
          sheet << row = XML::Node.new('row')
          row << XML::Node.new('cell')
          (@oo.first_column(sheet_name)..@oo.last_column(sheet_name)).each do |col|
            row << cell = XML::Node.new('cell')
            cell['class'] = 'column-index'
            cell << value = XML::Node.new('value')
            value << GenericSpreadsheet.number_to_letter(col)
          end
        end
        
      end        
    end
  end
end
