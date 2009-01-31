module Rasta  
  class HTML
    def initialize
      @tabs = []
      @pages = {}
    end
  
    def write(filename)
      fh = File.new(filename, 'w') 
      fh.puts header + tab_html + page_html + footer
      fh.close
    end
    
    def header
      <<-EOS
      <html>
      <head>
      
        <script src="http://code.jquery.com/jquery-latest.js"></script>
        <link rel="stylesheet" href="http://ui.jquery.com/latest/themes/flora/flora.all.css" type="text/css" media="screen" title="Flora (Default)">
        <script type="text/javascript" src="http://ui.jquery.com/latest/ui/ui.core.js"></script>
        <script type="text/javascript" src="http://ui.jquery.com/latest/ui/ui.tabs.js"></script>
        <script>
        $(document).ready(function(){
          $("#example > ul").tabs();
          
        });
        </script>
      </head>
      <body>
      <div id="example" class="flora">
      EOS
    end
  
    def footer
      <<-EOS
              </div>
      </body>
      </html>
      EOS
    end

    def add_tab(roo)
      sheet = roo.default_sheet
      @tabs << sheet
      @pages[sheet] = spreadsheet_html(roo)
    end
    
    def tab_html
      html = "            <ul>\n"
      @tabs.each_index do |i|
        html += "            <li><a href=\"#fragment-#{i+1}\"><span>#{@tabs[i]}</span></a></li>\n"
      end  
      html += "            </ul>"
      html
    end
    
    def page_html
      html = ''
      @tabs.each_index do |i|
        html += "            <div id=\"fragment-#{i+1}\">\n"
        html += @pages[@tabs[i]] + "\n"
        html += "            </div>\n"
      end
      html
    end
  
    # Based on roo's output functions
    def spreadsheet_html(spreadsheet, results = [])
      result = []
      o=""
      sheet = spreadsheet.default_sheet
      linenumber = spreadsheet.first_row(sheet) 
      o << '<table border="0" cellspacing="1" cellpadding="5">'
      first_row    = spreadsheet.first_row(sheet) 
      last_row     = spreadsheet.last_row(sheet)
      first_column = spreadsheet.first_column(sheet) 
      last_column  = spreadsheet.last_column(sheet) 
      o << "  <tr align=center>"
      o << "  <td>&nbsp;</td>"
      spreadsheet.first_column(sheet).upto(spreadsheet.last_column(sheet)) {|c| 
        if c < first_column or c > last_column
          next
        end
        o << "    <th>"
        o << "      <b>#{GenericSpreadsheet.number_to_letter(c)}</b>"
        o << "    </th>"
      } 
      o << "</tr>"
      spreadsheet.first_row.upto(spreadsheet.last_row) do |y|
        if first_row and (y < first_row or y > last_row)
          next
        end
        o << "<tr>"
        o << "<th>#{linenumber.to_s}</th>"
        linenumber += 1
        spreadsheet.first_column(sheet).upto(spreadsheet.last_column(sheet)) do |x|
          if x < first_column or x > last_column
            next
          end
          cell = spreadsheet.cell(y,x).to_s
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
            o << "#{spreadsheet.cell(y,x)}"
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