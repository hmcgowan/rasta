module Rasta  
  class HTML
    Html_dir = File.join(File.dirname(__FILE__), 'html')
    
    def initialize
      @tabs = []
      @pages = {}
    end
  
    def write(filename)
      fh = File.new(filename, 'w') 
      fh.puts header + tab_html + footer
      fh.close
    end
    
    def css
      css = "<style TYPE=\"text/css\" MEDIA=\"screen\">\n"
      rasta_css = File.new(File.join(Html_dir,'rasta.css'))
      css += rasta_css.read
      css += "</style>\n"
    end
    
    def javascript
      tabber = File.new(File.join(Html_dir,'tabber-minimized.js'))
      javascript = "<script TYPE=\"text/javascript\">\n"
      javascript += tabber.read
      javascript += "</script>\n"
    end
    
    def header
      header = <<-EOS
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Rasta Test Results</title>

<div class ="tabber">
EOS
      header += css + javascript      
      header += "</head>\n<body>\n"
      header
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
      html = ''
      @tabs.each do |tab|
        html +=  "  <div class=\"tabbertab\">\n"
        html += "    <h2>#{tab}</h2>\n"
        html += "    <p>#{@pages[tab]}</p>\n"
        html += "  </div>\n"
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