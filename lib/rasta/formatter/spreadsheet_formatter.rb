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
        
        def html_tabs
          tabs = ''
          current_sheet = @oo.default_sheet
          @oo.sheets.each do |sheet|
            @oo.default_sheet = sheet
            tabs +=  "  <div class=\"tabbertab\">\n"
            tabs += "    <h2>#{sheet}</h2>\n"
            tabs += "    #{html_spreadsheet}\n"
            tabs += "  </div>\n"
          end
          @oo.default_sheet = current_sheet
          tabs
        end

        def example_failed(example, counter, failure)
          @doc.find("//td[@id='#{@record}']")[0].attributes['class'] = 'failed'
          @doc.save(@output.path)
        end
        
        def example_passed(example)
          @doc.find("//td[@id='#{@record}']")[0].attributes['class'] = 'passed'
          @doc.save(@output.path)
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
              header += "</head>\n<body>\n<div class =\"tabber\">"
              header
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

        def dump_failure(*args); end
        def dump_summary(*args); end
        def dump_pending(*args); end

        def html_footer
          <<-EOS
    </div>
    </body>
    </html>
          EOS
        end
        
        def html_spreadsheet
          o=""
          sheet = @oo.default_sheet
          linenumber = @oo.first_row(sheet) 
          o << "<table id=\"#{sheet}\" summary=\"Test results for tab #{sheet}\" border=\"0\" cellspacing=\"1\" cellpadding=\"5\">"
          first_row    = @oo.first_row(sheet) 
          last_row     = @oo.last_row(sheet)
          first_column = @oo.first_column(sheet) 
          last_column  = @oo.last_column(sheet) 
          o << "<tr align=\"center\">"
          o << "<td>&nbsp;</td>"
          @oo.first_column(sheet).upto(@oo.last_column(sheet)) {|col| 
            if col < first_column or col > last_column
              next
            end
            o << "<th>"
            o << "<b>#{GenericSpreadsheet.number_to_letter(col)}</b>"
            o << "</th>"
          } 
          o << "</tr>"
          @oo.first_row.upto(@oo.last_row) do |row|
            if first_row and (row < first_row or row > last_row)
              next
            end
            o << "<tr>"
            o << "<th>#{linenumber.to_s}</th>"
            linenumber += 1
            @oo.first_column(sheet).upto(@oo.last_column(sheet)) do |col|
              if col < first_column or col > last_column
                next
              end
              cell = @oo.cell(row,col).to_s
              cell =~ /\A\S+\Z/ ? align = 'align=center' : align = ''
              o << "<td id=\"#{sheet}-#{GenericSpreadsheet.number_to_letter(col)}#{row}\" class=\"not_run\">"
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
