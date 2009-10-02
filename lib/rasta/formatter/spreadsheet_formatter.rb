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
        
        def node(name, value=nil, attrs={})
          node = XML::Node.new(name)
          attrs.each_pair { |k,v| node[k.to_s] = v}
          node << value if value
          node
        end
        
        def cell_node(value, attributes)
          node('cell', nil, attributes) << node('value', value)
        end
        
        def xsl_transform
          stylesheet_doc = XML::Document.file(File.join(Resource_dir, 'spreadsheet.xsl'))
          stylesheet = LibXSLT::XSLT::Stylesheet.new(stylesheet_doc)
          stylesheet.apply(@doc)
        end
        
        def add_tabber_javascript
          head = @doc.find_first("//*[local-name()='head']")
          head << tabber = XML::Node.new('script')
          tabber['type'] = "text/javascript"
          js = XML::Node.new_text(content = IO.readlines(File.join(File.dirname(__FILE__),'..','resources','tabber-minimized.js')).join)
          js.output_escaping = false
          tabber << js
          tabber
        end

        def add_css
          head = @doc.find_first("//*[local-name()='head']")
          head << style = XML::Node.new('style')
          style['type'] = "text/css"
          css = XML::Node.new_text(content = IO.readlines(File.join(File.dirname(__FILE__),'..','resources','spreadsheet.css')).join)
          css.output_escaping = false
          style << css
          style
        end

        def save
          @doc.save(@filename, :indent => true, :encoding => XML::Encoding::UTF_8)
        end
        
        def save_transform(file)
          @filename = file
          @doc = XML::Parser.document(xsl_transform).parse
          add_tabber_javascript
          add_css
          save
        end

      end
      
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseTextFormatter
        attr_accessor :oo, :record
        
        def initialize(*args)
          super
          @xml = SpreadsheetXML.new
        end

        # Stub out these methods because we don't need them
        def dump_failure(*args); end
        def dump_pending(*args); end
        
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
           @xml.summary << test_summary(example, 'passed')
           @xml.save
        end

        def example_failed(example, counter, failure)
           status = exception?(failure) ? 'exception' : 'failed'
           @xml.result['class']  = 'result'
           @xml.result['status'] = status
           @xml.result << @xml.node('detail', stack_trace(failure))
           if failure
             @xml.summary << test_summary(example, status, :message=>stack_trace(failure), :failure=>failure)
           else
             @xml.summary << test_summary(example, status)
           end
           @xml.save
        end
        
        def example_pending(example, message)
          @xml.result['class']  = 'result'
          @xml.result['status']  = 'pending'
          @xml.summary << test_summary(example, 'pending', :message=>message)
          @xml.save
        end
        
        # Update the totals on the Summary tab
        def dump_summary(duration, example_count, failure_count, pending_count)
          @xml.summary_totals << @xml.node('duration', duration)
          @xml.summary_totals << @xml.node('tests', example_count)
          @xml.summary_totals << @xml.node('failures', failure_count)
          @xml.summary_totals << @xml.node('pending', pending_count)
          @xml.save
        end

        def test_summary(example, classname, opts={})
          node = @xml.node('item', nil, :class=>classname) 
          node << @xml.node('title', "#{@record}: #{example.description}")
          if opts[:message]
            node << @xml.node('description', opts[:message].strip)
            node << code_snippet(opts[:failure]) if exception?(opts[:failure])
          end  
          node
        end
       
        def code_snippet(failure)
          require 'spec/runner/formatter/snippet_extractor'
          return unless failure.exception.backtrace && failure.exception.backtrace != []
          @snippet_extractor ||= SnippetExtractor.new
          (raw_code, linenum) = @snippet_extractor.snippet_for(failure.exception.backtrace[0]) 
          node = @xml.node('exception')
          raw_code.split("\n").each_with_index do |line, l|
            value = "#{l + linenum - 2}: " + line.strip
            if l == 2
              node << @xml.node('line', value, :class=>'offending')
            else
              node << @xml.node('line', value, :class=>'linenum')
            end
          end
          node
        end
        
        def stack_trace(failure)
          failure.exception.backtrace ? failure.exception.message + "\n" + failure.exception.backtrace.join("\n") : failure.exception.message 
        end
        
        def exception?(failure)
          failure && failure.exception.backtrace && failure.exception.backtrace != []
        end

        
        def add_xml_worksheets
          current_sheet = @oo.default_sheet
          @oo.sheets.each do |sheet|
            @oo.default_sheet = sheet
            next unless @oo.first_column(sheet) #skip empty worksheets
            @xml.spreadsheet << worksheet(sheet)
          end
          @oo.default_sheet = current_sheet
        end
        
        def worksheet(sheet)
          line_number = @oo.first_row(sheet) 
          node = @xml.node('sheet', nil, :id=>sheet)
          node << before_after_cells
          node << column_header
          each_row do |row|
            node <<  worksheet_cells(row, line_number)
            line_number += 1
          end
          node
        end

        def before_after_cells
          sheet_name = @oo.default_sheet
          node = @xml.node('setup')
          node << @xml.cell_node('before_all', :id=>'before_all', :status=>'not_run')
          node << @xml.cell_node('after_all', :id=>'after_all', :status=>'not_run')
          node
        end

        def worksheet_cells(name, line)
          sheet_name = @oo.default_sheet
          records = @oo.records(sheet_name)
          node = @xml.node('row')
          row_name = line.to_s
          node << @xml.cell_node(row_name, :id=>row_name, :status=>'not_run')
          each_column do |col_name|
            cell_value = @oo.cell(name,col_name).to_s
            if (records.type == :column && col_name == records.header_index) || records.type == :row && name == records.header_index
              node << @xml.cell_node(@oo.cell(name,col_name).to_s, :class=>'header')
            else
              id = "#{GenericSpreadsheet.number_to_letter(col_name)}#{name}"
              node << @xml.cell_node(cell_value, :id=>id, :status=>'not_run')
            end
          end
          node
        end
                
        def column_header
          sheet_name = @oo.default_sheet
          node = @xml.node('row')
          node << @xml.node('cell')
          each_column do |col|
            column_name = GenericSpreadsheet.number_to_letter(col)
            node << @xml.cell_node(column_name, :id=>column_name, :status=>'not_run')
          end
          node
        end
        
        def each_column
          (@oo.first_column..@oo.last_column).each { |col| yield col }
        end

        def each_row
          (@oo.first_row..@oo.last_row).each { |row| yield row }
        end
        
      end        
    end
  end
end
