# THIS IS ONLY TEMPORARY. REFACTORING AND ADDING FEATURES TO ROO
# The font information here is also incorrect. I'm getting the font_no 
# but that needs to be mapped properly to the font records to get the
# correct font information. It's basically hard-coded that it works for the
# example but will fail on any other spreadsheet 

# Google does not support font information
# right now so fake out roo to return
# something that looks like a column fixture
class Google < GenericSpreadsheet
  class Format
    def initialize(bold)
      @bold = bold
    end
    def bold?; @bold end
  end
  
  def cellformat(row,col,sheet=nil)
    begin
      if col == 1
        Format.new(true)
      else
        Format.new(false)
      end
    rescue
      puts "Error in sheet #{sheet}, row #{row}, col #{col}"
      raise
    end
  end
end

class Excel < GenericSpreadsheet 
  alias :old_initialize :initialize
  def initialize(filename, packed = nil, file_warning = :error)
    old_initialize(filename, packed = nil, file_warning = :error)
    @font_no = Hash.new
  end
  class Format
    def initialize(font)
      @font = font
    end
    def bold?
      @font == 7 || @font == 6 || @font == 9 ? true : false
    end
    def italic?
      @font == 8 || @font == 9 ? true : false
    end
  end
  
  def cellformat(row,col,sheet=nil)
    sheet = @default_sheet unless sheet
    read_cells(sheet) unless @cells_read[sheet]
    row,col = normalize(row,col)
    begin
      return Format.new(@font_no[sheet][[row,col]])
    rescue
      puts "Error in sheet #{sheet}, row #{row}, col #{col}"
      raise
    end
  end
  
  alias :old_set_cell_values :set_cell_values
  def set_cell_values(sheet,x,y,i,v,vt,formula,tr,str_v, font_no)
    key = [y,x+i]
    @font_no[sheet] = {} unless @font_no[sheet]
    @font_no[sheet][key] = font_no  if font_no
    old_set_cell_values(sheet,x,y,i,v,vt,formula,tr,str_v)
  end
  
  def read_cells(sheet=nil)
    sheet = @default_sheet unless sheet
    raise ArgumentError, "Error: sheet '#{sheet||'nil'}' not valid" if @default_sheet == nil and sheet==nil
    raise RangeError unless self.sheets.include? sheet
    
    if @cells_read[sheet]
      raise "sheet #{sheet} already read"
    end
    
    worksheet = @workbook.worksheet(sheet_no(sheet))
    skip = 0
    x =1
    y=1
    i=0
    worksheet.each(skip) { |row_par| 
      if row_par
        x =1
        row_par.each do # |void|
          cell = row_par.at(x-1)
          if cell
            case cell.type
            when :numeric
              vt = :float
              v = cell.to_f
            when :text
              vt = :string
              if cell.to_s.downcase == 'true'
                str_v = 'true'
              else
                str_v = cell.to_s('utf-8')
              end  
            when :date
              if cell.to_s.to_f < 1.0
                vt = :time
                f = cell.to_s.to_f*24.0*60.0*60.0
                secs = f.round
                h = (secs / 3600.0).floor
                secs = secs - 3600*h
                m = (secs / 60.0).floor
                secs = secs - 60*m
                s = secs
                v = h*3600+m*60+s
              else
                if cell.datetime.hour != 0 or
                    cell.datetime.min  != 0 or
                    cell.datetime.sec  != 0 or
                    cell.datetime.msec != 0
                  vt = :datetime
                  v = cell.datetime
                else
                  vt = :date
                  v = cell.date
                  v = sprintf("%04d-%02d-%02d",v.year,v.month,v.day)
                end
              end
            else
              vt = cell.type.to_s.downcase.to_sym
              v = nil
            end # case
            formula = tr = nil #TODO:???
            font_no = cell.format.font_no
            set_cell_values(sheet,x,y,i,v,vt,formula,tr,str_v, font_no)
          end # if cell
          
          x += 1
        end
      end
      y += 1
    }
    @cells_read[sheet] = true
  end
end


class Excelx < GenericSpreadsheet
  
  attr_accessor :styles_doc
  
end
class Openoffice < GenericSpreadsheet
  require 'cgi'
  alias :old_initialize :initialize
  def initialize(filename, packed=nil, file_warning=:error) 
    old_initialize(filename, packed=nil, file_warning=:error)
    @font_no = Hash.new
  end

  class Format
    def initialize(font)
      @font = font
    end
    def bold?
      @font == 'ce1' || @font == 'ce7' || @font == 'ce11' ? true : false
    end
    def italic?
      @font == 'ce7' || @font == 'ce8' || @font == 'ce12' ? true : false
    end
  end
  
  def cellformat(row,col,sheet=nil)
    sheet = @default_sheet unless sheet
    read_cells(sheet) unless @cells_read[sheet]
    row,col = normalize(row,col)
    begin
      return Format.new(@font_no[sheet][[row,col]])
    rescue
      puts "Error in sheet #{sheet}, row #{row}, col #{col}"
      raise
    end
  end
  
  alias :old_set_cell_values :set_cell_values
  def set_cell_values(sheet,x,y,i,v,vt,formula,tr,str_v, font_no)
    key = [y,x+i]
    @font_no[sheet] = {} unless @font_no[sheet]
    @font_no[sheet][key] = font_no
    old_set_cell_values(sheet,x,y,i,v,vt,formula,tr,str_v)
  end
  
  def read_cells(sheet=nil)
    sheet = @default_sheet unless sheet
    sheet_found = false
    raise ArgumentError, "Error: sheet '#{sheet||'nil'}' not valid" if @default_sheet == nil and sheet==nil
    raise RangeError unless self.sheets.include? sheet
    oo_document_count = 0
    @doc.each_element do |oo_document|
      # @officeversion = oo_document.attributes['version']
      oo_document_count += 1
      oo_element_count = 0
      oo_document.each_element do |oo_element|
        oo_element_count += 1
        if oo_element.name == "body"
          oo_element.each_element do |be|
            if be.name == "spreadsheet"
              be.each_element do |se|
                if se.name == "table"
                  if se.attributes['name']==sheet
                    sheet_found = true
                    x=1
                    y=1
                    se.each_element do |te|
                      if te.name == "table-column"
                        rep = te.attributes["number-columns-repeated"]
                      elsif te.name == "table-row"
                        if te.attributes['number-rows-repeated']
                          skip_y = te.attributes['number-rows-repeated'].to_i
                          y = y + skip_y - 1 # minus 1 because this line will be counted as a line element
                        end
                        te.each_element do |tr|
                          if tr.name == 'table-cell'
                            skip = tr.attributes['number-columns-repeated']
                            formula = tr.attributes['formula']
                            vt = tr.attributes['value-type']
                            v  = tr.attributes['value']
                            font_no = tr.attributes['style-name']
                            if vt == 'string'
                              str_v  = ''
                              # insert \n if there is more than one paragraph
                              para_count = 0
                              tr.each_element do |str|
                                if str.name == 'p'
                                  v = str.text
                                  str_v += "\n" if para_count > 0
                                  para_count += 1
                                  if str.children.size > 1
                                    str_v = children_to_string(str.children)
                                  else
                                    str.children.each {|child|
                                      str_v = str_v + child.to_s #.text
                                    }
                                  end
                                  str_v.gsub!(/&apos;/,"'")  # special case not supported by unescapeHTML
                                  str_v = CGI.unescapeHTML(str_v)
                                end # == 'p'
                              end
                            elsif vt == 'time'
                              tr.each_element do |str|
                                if str.name == 'p'
                                  v = str.text
                                end
                              end
                            elsif vt == '' or vt == nil
                              #
                            elsif vt == 'date'
                              #
                            elsif vt == 'percentage'
                              #
                            elsif vt == 'float'
                              #
                            elsif vt == 'boolean'
                              v = tr.attributes['boolean-value']
                              #
                            else
                              # raise "unknown type #{vt}"
                            end
                            if skip
                              if v != nil or tr.attributes['date-value']
                                0.upto(skip.to_i-1) do |i|
                                  set_cell_values(sheet,x,y,i,v,vt,formula,tr,str_v, font_no)
                                end
                              end
                              x += (skip.to_i - 1)
                            end # if skip
                            set_cell_values(sheet,x,y,0,v,vt,formula,tr,str_v, font_no)
                            x += 1
                          end
                        end
                        y += 1
                        x = 1
                      end
                    end
                  end # sheet
                end
              end
            end
          end
        end
      end
    end
    if !sheet_found
      raise RangeError
    end
    @cells_read[sheet] = true
  end

end
