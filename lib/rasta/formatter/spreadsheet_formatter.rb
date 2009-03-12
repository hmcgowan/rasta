Resource_dir = File.join(File.dirname(__FILE__), '..', 'resources')

require 'spec/runner/formatter/base_formatter'

module Spec
  module Runner
    module Formatter
      class SpreadsheetFormatter <  Spec::Runner::Formatter::BaseTextFormatter
        attr_writer :oo, :record
        
        def initialize(options, output)
          @@results ||= {}
          super
        end
        
        def start(example_count)
          @example_count = example_count
          @output.puts html_header
          @output.puts html_tabs
          @output.flush
        end
        
        def html_tabs
          tabs = ''
          @oo.sheets.each do |sheet|
            @oo.default_sheet = sheet
            tabs +=  "  <div class=\"tabbertab\">\n"
            tabs += "    <h2>#{sheet}</h2>\n"
            tabs += "    <p>#{html_spreadsheet}</p>\n"
            tabs += "  </div>\n"
          end
          tabs
        end

        def example_failed(example, counter, failure)
          # @@results[@cell] = :fail
          # @fixture.write_html(@@results) if @fixture
          
#          if @cell 
#            failure.exception.backtrace ? @cell.color = YELLOW : @cell.color = RED
#            comment = "method: " + @cell.header + "()\n"
#            comment += failure.exception.message.gsub(/,\s+/,",\n")  
#            comment += "\n" + failure.exception.backtrace.join("\n") if failure.exception.backtrace
#            @cell.comment = comment
#          end
        end
        
        def example_passed(example)
          # @@results[@cell] = :fail
          # @fixture.write_html(@@results) if @fixture
        end

        def html_header
              header = <<-EOS
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Rasta Test Results</title>

<div class ="tabber">
EOS
              header += html_style + html_javascript      
              header += "</head>\n<body>\n"
              header
        end
       
        def html_style
          css = "<style TYPE=\"text/css\" MEDIA=\"screen\">\n"
          rasta_css = File.new(File.join(Resource_dir,'rasta.css'))
          css += rasta_css.read
          css += "</style>\n"
        end

        def html_javascript
          tabber = File.new(File.join(Resource_dir,'tabber-minimized.js'))
          javascript = "<script TYPE=\"text/javascript\">\n"
          javascript += tabber.read
          javascript += "</script>\n"
        end


        def footer
          <<-EOS
    </div>
    </body>
    </html>
          EOS
        end
        
        def html_spreadsheet(results = [])
          result = []
          o=""
          sheet = @oo.default_sheet
          linenumber = @oo.first_row(sheet) 
          o << '<table border="0" cellspacing="1" cellpadding="5">'
          first_row    = @oo.first_row(sheet) 
          last_row     = @oo.last_row(sheet)
          first_column = @oo.first_column(sheet) 
          last_column  = @oo.last_column(sheet) 
          o << "  <tr align=center>"
          o << "  <td>&nbsp;</td>"
          @oo.first_column(sheet).upto(@oo.last_column(sheet)) {|c| 
            if c < first_column or c > last_column
              next
            end
            o << "    <th>"
            o << "      <b>#{GenericSpreadsheet.number_to_letter(c)}</b>"
            o << "    </th>"
          } 
          o << "</tr>"
          @oo.first_row.upto(@oo.last_row) do |y|
            if first_row and (y < first_row or y > last_row)
              next
            end
            o << "<tr>"
            o << "<th>#{linenumber.to_s}</th>"
            linenumber += 1
            @oo.first_column(sheet).upto(@oo.last_column(sheet)) do |x|
              if x < first_column or x > last_column
                next
              end
              cell = @oo.cell(y,x).to_s
              cell =~ /\A\S+\Z/ ? align = 'align=center' : align = ''
              case results[x,y]
              when :pass
                o << "<td #{align} bgcolor=\"lightgreen\">"
              when :fail
                o << "<td #{align} bgcolor=\"lightred\">"
              else  
                o <<  "<td #{align} bgcolor=\"\">"
              end
              if cell.empty?
                o << "&nbsp;"
              else
                o << "#{@oo.cell(y,x)}"
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

# module Rasta  
#   class HTML
#     
#     def initialize
#       @tabs = []
#       @pages = {}
#     end
#   
#     def write(filename)
#       fh = File.new(filename, 'w') 
#       fh.puts header + tab_html + footer
#       fh.close
#     end
#     
#     def add_tab(roo)
#       sheet = roo.default_sheet
#       @tabs << sheet
#       @pages[sheet] = spreadsheet_html(roo)
#     end
#     
#     def tab_html
#       html = ''
#       @tabs.each do |tab|
#         html +=  "  <div class=\"tabbertab\">\n"
#         html += "    <h2>#{tab}</h2>\n"
#         html += "    <p>#{@pages[tab]}</p>\n"
#         html += "  </div>\n"
#       end  
#       html
#     end
#     
#     # Based on roo's output functions
#     def spreadsheet_html(spreadsheet, results = [])
#       result = []
#       o=""
#       sheet = spreadsheet.default_sheet
#       linenumber = spreadsheet.first_row(sheet) 
#       o << '<table border="0" cellspacing="1" cellpadding="5">'
#       first_row    = spreadsheet.first_row(sheet) 
#       last_row     = spreadsheet.last_row(sheet)
#       first_column = spreadsheet.first_column(sheet) 
#       last_column  = spreadsheet.last_column(sheet) 
#       o << "  <tr align=center>"
#       o << "  <td>&nbsp;</td>"
#       spreadsheet.first_column(sheet).upto(spreadsheet.last_column(sheet)) {|c| 
#         if c < first_column or c > last_column
#           next
#         end
#         o << "    <th>"
#         o << "      <b>#{GenericSpreadsheet.number_to_letter(c)}</b>"
#         o << "    </th>"
#       } 
#       o << "</tr>"
#       spreadsheet.first_row.upto(spreadsheet.last_row) do |y|
#         if first_row and (y < first_row or y > last_row)
#           next
#         end
#         o << "<tr>"
#         o << "<th>#{linenumber.to_s}</th>"
#         linenumber += 1
#         spreadsheet.first_column(sheet).upto(spreadsheet.last_column(sheet)) do |x|
#           if x < first_column or x > last_column
#             next
#           end
#           cell = spreadsheet.cell(y,x).to_s
#           cell =~ /\A\S+\Z/ ? align = 'align=center' : align = ''
#           case results[x,y]
#           when :pass
#             o << "<td #{align} bgcolor=\"lightgreen\">"
#           when :fail
#             o << "<td #{align} bgcolor=\"lightred\">"
#           else  
#             o <<  "<td #{align} bgcolor=\"\">"
#           end
#           if cell.empty?
#             o << "&nbsp;"
#           else
#             o << "#{spreadsheet.cell(y,x)}"
#           end
#           o << "</td>"
#         end
#         o << "</tr>"
#       end
#       o << "</table>"
#     
#       return o
#     end
#     
#   end
# end