# TODO: put name of spreadsheet on the page
# and think about how to handle multiple spreadsheets
#
# handle xslt paths
# need to parse for spreadsheet name if Google

Resource_dir = File.join(File.dirname(__FILE__), '..', 'resources')
require 'spec/runner/formatter/base_text_formatter'
require 'xml'
require 'xslt'

module Spec
  module Runner
    module Formatter
      
      class SpreadsheetXML
        attr_accessor :sheet, :cell, :spreadsheet
        
        def initialize
          LibXML::XML.indent_tree_output = true
          LibXML::XML.default_tree_indent_string = '  '
        end
        
        def header
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?><spreadsheet><summary filename=\"#{@spreadsheet}\"><totals></totals></summary></spreadsheet>"
        end
        
        def read(file)
          @filename = file.path
          @doc = LibXML::XML::Parser.file(@filename).parse
        end
          
        def result
          @doc.find_first("/spreadsheet/sheet[@id='#{@sheet}']//cell[@id='#{@cell}']")
        end

        def summary
          @doc.find_first("/spreadsheet/summary")
        end  
        
        def summary_totals
          @doc.find_first("/spreadsheet/summary/totals")
        end
        
        def spreadsheet
          @doc.find_first('/spreadsheet')
        end
        
        def add_node(name, value=nil, attrs={})
          node = XML::Node.new(name)
          attrs.each_pair { |k,v| node[k.to_s] = v}
          node << value if value
          node
        end
        
        def xsl_transform
          stylesheet_doc = XML::Document.file(File.join(Resource_dir, 'spreadsheet.xsl'))
          stylesheet = LibXSLT::XSLT::Stylesheet.new(stylesheet_doc)
          stylesheet.apply(@doc, {:root => "ROOT", :back => "BACK"})
        end
        
        def save
          @doc.save(@filename, :indent => true, :encoding => XML::Encoding::UTF_8)
        end
        
        def save_transform(file)
          @filename = file
          @doc = XML::Parser.document(xsl_transform).parse
          save
        end

      end
      
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseTextFormatter
        attr_accessor :oo, :record
        
        def initialize(*args)
          super
          @xml = SpreadsheetXML.new
        end

        def oo=(x)        
          @oo=x
          @xml.spreadsheet = File.basename(@oo.filename)
        end  

        # Store a reference to the spreadsheet record 
        # so we can update the associated cell in the output
        def record=(x)
          @record = x
          (@sheet, @cell) = @record.split('-')
          @xml.sheet = @sheet
          @xml.cell = @cell
        end
        
        def start(example_count)
          @example_count = example_count
          @total_count = 0
          @total_passed = 0
          @total_failed = 0
          @total_exception = 0
          @total_pending = 0
          @output.puts @xml.header
          @output.flush
          @xml.read @output
          add_xml_worksheets
          @xml.save
        end
        
        def close
          @xml.save_transform @output.path.gsub('xml','html')
        end
        
        def example_passed(example)
           @xml.result['class']  = 'result'
           @xml.result['status']  = 'passed'
           update_test_summary(example, 'passed')
           @xml.save
        end

        def example_failed(example, counter, failure)
           status = exception?(failure) ? 'exception' : 'failed'
           @xml.result['class']  = 'result'
           @xml.result['status'] = status
           @xml.result << @xml.add_node('detail', failure_exception(failure))
           message = failure_exception(failure) if failure
           update_test_summary(example, status, :message=>message, :failure=>failure)
           @xml.save
        end
        
        def example_pending(example, message)
          @xml.result['class']  = 'result'
          @xml.result['status']  = 'pending'
          update_test_summary(example, 'pending', :message=>message)
          @xml.save
        end
        
        
        # Stub out these methods because we don't need them
        def dump_failure(*args); end
        def dump_pending(*args); end
        
        # Update the totals on the Summary tab
        def dump_summary(duration, example_count, failure_count, pending_count)
          @xml.summary_totals << @xml.add_node('duration', duration)
          @xml.summary_totals << @xml.add_node('tests', example_count)
          @xml.summary_totals << @xml.add_node('failures', failure_count)
          @xml.summary_totals << @xml.add_node('pending', pending_count)
          @xml.save
        end

        def update_test_summary(example, classname, opts={})
          @xml.summary << summary_item = @xml.add_node('item', nil, :class=>classname) 
          summary_item << @xml.add_node('title', "#{@record}: #{example.description}")
          if opts[:message]
            summary_item << @xml.add_node('description', opts[:message].strip)
            summary_item << code_snippet(opts[:failure]) if exception?(opts[:failure])
          end  
        end
       
        def code_snippet(failure)
          require 'spec/runner/formatter/snippet_extractor'
          return unless failure.exception.backtrace && failure.exception.backtrace != []
          @snippet_extractor ||= SnippetExtractor.new
          (raw_code, linenum) = @snippet_extractor.snippet_for(failure.exception.backtrace[0]) 
          node = @xml.add_node('exception')
          raw_code.split("\n").each_with_index do |line, l|
            value = "#{l + linenum - 2}: " + line.strip
            if l == 2
              node << @xml.add_node('line', value, :class=>'offending')
            else
              node << @xml.add_node('line', value, :class=>'linenum')
            end
          end
          node
        end
        
        def failure_exception(failure)
          failure.exception.backtrace ? failure.exception.message + "\n" + failure.exception.backtrace.join("\n") : failure.exception.message 
        end

        
        def exception?(failure)
          failure && failure.exception.backtrace && failure.exception.backtrace != []
        end


        def table_cell(value, attributes)
          @xml.add_node('cell', nil, attributes) << @xml.add_node('value', value)
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
          @xml.spreadsheet << xml_sheet = @xml.add_node('sheet', nil, :id=>sheet_name)
          add_xml_before_after_placeholders(xml_sheet)
          add_xml_worksheet_column_header(xml_sheet)
          @oo.first_row.upto(@oo.last_row) do |row_name|
            xml_sheet << xml_row = @xml.add_node('row', nil)
            xml_row << table_cell(linenumber.to_s, :class=>'row-index')
            linenumber += 1
            add_xml_worksheet_cell_values(xml_row, row_name)
          end
        end

        def add_xml_before_after_placeholders(xml_sheet)
          sheet_name = @oo.default_sheet
          xml_sheet << xml_row = XML::Node.new('setup')
          xml_row << table_cell('before_all', :id=>'before_all', :status=>'not_run')
          xml_row << table_cell('after_all', :id=>'after_all', :status=>'not_run')
        end

        def add_xml_worksheet_cell_values(xml_row, row_name)
          sheet_name = @oo.default_sheet
          records = @oo.records(sheet_name)
          @oo.first_column(sheet_name).upto(@oo.last_column(sheet_name)) do |col_name|
            cell_value = @oo.cell(row_name,col_name).to_s
            if (records.type == :column && col_name == records.header_index) || records.type == :row && row_name == records.header_index
              xml_row << table_cell(@oo.cell(row_name,col_name).to_s, :class=>'header')
            else
              id = "#{GenericSpreadsheet.number_to_letter(col_name)}#{row_name}"
              xml_row << table_cell(cell_value, :id=>id, :status=>'not_run')
            end
          end
        end
                
        def add_xml_worksheet_column_header(xml_sheet)
          sheet_name = @oo.default_sheet
          xml_sheet << xml_row = XML::Node.new('row')
          xml_row << XML::Node.new('cell')
          (@oo.first_column(sheet_name)..@oo.last_column(sheet_name)).each do |col|
            xml_row << table_cell( GenericSpreadsheet.number_to_letter(col), :class=>'column-index')
          end
        end
        
      end        
    end
  end
end
