# TODO: put name of spreadsheet on the page
# and think about how to handle multiple spreadsheets

Resource_dir = File.join(File.dirname(__FILE__), '..', 'resources')
require 'spec/runner/formatter/base_formatter'
require 'xml'
module Spec
  module Runner
    module Formatter
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseTextFormatter
        attr_accessor :oo, :record
        
        def start(example_count)
          @example_count = example_count
          @output.puts html_header
          @output.puts html_tabs
          @output.puts html_footer
          @output.flush
          parser = XML::HTMLParser.file(@output.path)
          @doc = parser.parse
        end
        
        def example_passed(example)
          table_cell = @doc.find("//td[@id='#{@record}']")[0]
          table_cell.attributes['class'] = 'passed'
          @doc.save(@output.path)
        end

        def example_failed(example, counter, failure)
          message = @record + "\n" + failure.exception.message
          table_cell = @doc.find("//td[@id='#{@record}']")[0]
          if failure.exception.backtrace
            message += failure.exception.backtrace.join("\n")
            table_cell.attributes['class'] = "exception"
  #          add_test_detail(message)
            add_tooltip(table_cell, message)
          else
            table_cell.attributes['class'] = "failed" 
  #          add_test_detail(message)
            add_tooltip(table_cell, message)
          end
          @doc.save(@output.path)
        end

        def example_pending(example, message, pending_caller)
          message = "#{@record} #{example.description} (#{message})"
          table_cell =  @doc.find("//td[@id='#{@record}']")[0]
          table_cell.attributes['class'] = 'pending'
  #        add_test_detail(message)
          add_tooltip(table_cell, message)
          @doc.save(@output.path)
        end
        
        # Stub out these methods because we don't need them
        def dump_failure(*args); end
        def dump_summary(*args); end
        def dump_pending(*args); end

  
        # Inject a div with test detail information as a child of the html_info div
        def add_test_detail(text)
          @doc.find("//div[@class='#{@oo.default_sheet}-information']")[0] << div = XML::Node.new('div')
          div['id'] = "#{@record}"
          div << pre = XML::Node.new('pre')
          pre << XML::Node.new_text(text.strip)
        end

        def add_tooltip(table_cell, text)
          table_cell << span = XML::Node.new('span')
          span << pre = XML::Node.new('pre')
          pre << XML::Node.new_text(text.strip)
        end

        def html_header
          header = <<-EOS
                  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
                  <html lang="en">
                  <head>
                  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"/>
                  <title>Rasta Test Results</title>
                  EOS
          header += html_style + html_javascript      
          header += <<-EOS
                    </head>
                    <body>
                    <div class="tabber">
                    EOS
          header
        end

        # show the spreadsheet in it's entirety
        def html_tabs
          tabs = ''
          current_sheet = @oo.default_sheet
          tabs += html_summary_tab
          @oo.sheets.each do |sheet|
            @oo.default_sheet = sheet
            tabs += "  <div class=\"tabbertab\">\n"
            tabs += "    <h2>#{sheet}</h2>\n"
            tabs += "    #{html_spreadsheet}\n\n"
#            tabs += "    <div class=\"#{sheet}-information\"/>"
            tabs += "  </div>\n"
          end
          @oo.default_sheet = current_sheet
          tabs
        end
       
        def html_summary_tab
          @oo.info =~ /File: (\S+)/
          spreadsheet_name = $1 || 'Google Spreadsheet'
          summary = <<-EOS
                      <div class="tabbertab">
                        <h2>Summary</h2>
                        <table class="summary" summary ="Summary of test results">
                        <tr><td class="summary-title">Filename</td><td class="summary-detail-text">#{spreadsheet_name}</td></tr>
                        <tr><td class="summary-title">Tests Run</td><td class="summary-detail-number">0</td></tr>
                        <tr><td class="summary-title">Passed</td><td class="summary-detail-number">0</td></tr>
                        <tr><td class="summary-title">Failed</td><td class="summary-detail-number">0</td></tr>
                        <tr><td class="summary-title">Pending</td><td class="summary-detail-number">0</td></tr>
                        <tr><td class="summary-title">Execution Time</td><td class="summary-detail-number">0</td></tr>
                        </table>
                      </div>
                    EOS
        end
        
        def html_style
#          rasta_css = File.new(File.join(Resource_dir,'rasta.css'))
#          css = "<style TYPE=\"text/css\" MEDIA=\"screen\">\n"
#          css += rasta_css.read
#          css += "</style>\n"
          "<LINK href=\"#{File.join(Resource_dir,'rasta.css')}\" rel=\"stylesheet\" type=\"text/css\">"
        end

        def html_javascript
          #tabber = File.new(File.join(Resource_dir,'tabber-minimized.js'))
          #javascript = "<script TYPE=\"text/javascript\">\n"
          #javascript += tabber.read
          #javascript += "</script>\n"
          "<script src=\"#{File.join(Resource_dir,'tabber-minimized.js')}\"> </script>"
        end

        def html_footer
          <<-EOS
            </div>
            </body>
          </html>
          EOS
        end
        
        #need to look at refactoring because we should be able to ust use records
        # since we need them anyway
        def html_spreadsheet
          o=""
          sheet = @oo.default_sheet
          linenumber = @oo.first_row(sheet) 
          o << "<table id=\"#{sheet}\" summary=\"Test results for tab #{sheet}\" border=\"0\" cellspacing=\"1\" cellpadding=\"5\">"
          o << "<tr class=\"column-index\" align=\"center\">"
          o << "<td>&nbsp;</td>"
          records = @oo.records(sheet)
          @oo.first_column(sheet).upto(@oo.last_column(sheet)) {|col| 
            o << "<td class=\"column-index\">#{GenericSpreadsheet.number_to_letter(col)}</td>"
          } 
          o << "</tr>"
          @oo.first_row.upto(@oo.last_row) do |row|
            o << "<tr>"
            o << "<td class=\"row-index\">#{linenumber.to_s}</td>"
            linenumber += 1
            @oo.first_column(sheet).upto(@oo.last_column(sheet)) do |col|
              if (records.type == :column && col == records.header_index) || records.type == :row && row == records.header_index
                td_class = 'header'
              else
                td_class = 'not_run'
              end
              cell = @oo.cell(row,col).to_s
              cell =~ /\A\S+\Z/ ? align = 'align=center' : align = ''
              o << "<td id=\"#{sheet}-#{GenericSpreadsheet.number_to_letter(col)}#{row}\" class=\"#{td_class}\">"
              if cell.empty?
                o << "&nbsp;"
              else
                o << "#{CGI::escapeHTML(@oo.cell(row,col).to_s)}"
              end
              o << "</td>"
            end
            o << "</tr>"
          end
          o << "</table>"
        
          return o
        end
    

      end        
    end
  end
end
