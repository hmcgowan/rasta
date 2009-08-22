require 'rasta/extensions/ruby_extensions'

# Google does not support font information
# right now so fake out roo to return
# something that looks like a column fixture
class GenericSpreadsheet; end
class Google < GenericSpreadsheet
  def font(row,col,sheet=nil)
    begin
      if col == 1
        Font.new(true)
      else
        Font.new(false)
      end
    rescue
      puts "Error in sheet #{sheet}, row #{row}, col #{col}"
      raise
    end
  end
  class Font
    def initialize(forced_value)
      @bold = forced_value
    end
    def bold?
      @bold
    end
  end
end

class GenericSpreadsheet
  attr_reader :filename
  def records(sheet = nil)
    Roo::Records.new(self, sheet)
  end
end

module Roo
  
  class RecordParseError < RuntimeError; end
  class RecordRangeError < RangeError; end

  class RecordCell
    attr_accessor :name, :value, :header
    def initialize(name, value, header)
      @name = name
      @value = value.postprocess
      @header = header
    end
    
    def empty?
      (value.nil? || value == '' || header.nil? || header == '') ? true : false
    end
  end
  
  class Record
    attr_accessor :record_cells, :header, :name

    def each
      @record_cells.each { |cell| yield cell }
    end 
    
    # return the cell value at a given header
    def [](x)
      case x
      when String
        begin
          @record_cells[@header.index(x)]
        rescue TypeError
          raise RecordRangeError, "No header value exists for: #{x}"
        end
      when Integer  
        @record_cells[x]
      end
    end
    
    def to_h
      result = {}
      @header.each {|h| result[h] = self[h] }
      result 
    end
    
    def to_a
      result = []
      @record_cells.each {|c| result << c.value }
      result 
    end
  end
  
  class Records
    
    def initialize(oo, sheet)
      @oo = oo
      @oo.default_sheet = sheet if sheet
      @record_list = []
      @header = RecordHeader.new(@oo)
    end
    
    def type; @header.type; end
    def header; @header.values; end
    def header_index; @header.index; end
    def first_record; @header.first_record; end
    def last_record; @header.last_record; end
    
    def each(&block)
      (@header.first_record..@header.last_record).each do |index|
        yield self[index]
      end
    end

    def [](x)
      return @record_list[x] if @record_list[x]
      @record_list[x] = Record.new
      @record_list[x].header = @header.values
      @record_list[x].record_cells = record_cells(x)
      @record_list[x].name = x
      @record_list[x]
    end
    
    def to_a
      result = []
      self.each { |record| result << record.to_a }
      result
    end
    
    def to_h
      result = []
      self.each { |record| result << record.to_h }
      result
    end
    
    def record_cells(x)
      record_values = []
      case @header.type
      when :row
        raise RecordParseError, "Record out of range. #{x} not in #{@oo.first_column}..#{@oo.last_column}" unless (@oo.first_row..@oo.last_row) === x
        (@oo.first_column..@oo.last_column).each do |col|
          record_values << (@oo.font(x,col).italic? ? nil : @oo.cell(x,col))  
        end
      when :column
        raise RecordParseError, "Record out of range. #{x} not in #{@oo.first_column}..#{@oo.last_column}" unless (@oo.first_column..@oo.last_column) === x
        (@oo.first_row..@oo.last_row).each do |row|
          record_values << (@oo.font(row,x).italic? ? nil :  @oo.cell(row, x) )
        end
      end
      cells = []
      idx = @header.first_record - 1
      record_values.each do |val|
        val = val.to_datatype if val.class == String
        name = nil
        if @type == :row
          name = GenericSpreadsheet.number_to_letter(idx) + x.to_s
          hdr = @header.values[idx-1]
        else
          name = GenericSpreadsheet.number_to_letter(x) + idx.to_s
          hdr = @header.values[idx-1]
        end
        cells << RecordCell.new(name, val, hdr)
        idx += 1
      end
      cells
    end
    
  end 
  class RecordHeader
    attr_accessor :first_record, :last_record, :index, :values, :type
    def initialize(oo)
      @oo = oo
      locate
    end
    
    # Find the header by scanning the spreadsheet and
    # testing each cell until we've found the header
    def locate
      return if (@oo.default_sheet == @current_sheet) 
      @values = nil
      @current_sheet = @oo.default_sheet
      if @oo.last_row && @oo.last_column
        (1..@oo.last_row).each do |row|
          (1..@oo.last_column).each do |col|
            next if @oo.empty?(row,col)
            return if found_header?(row,col)
          end     
        end
      end
      raise RecordParseError, "Unable to locate header row for #{@oo.default_sheet}" unless @values
    end    
    
    def found_header?(row, col)
      return true if @values

      # The headers are determined by the cell's font being bold
      if @oo.font(row,col).bold?

        # See if this is a column format where the values
        # for each record correspond to spreadsheet rows
        #   *header*, *header*
        #   value, value
        #   value, value
        # 
        # We check this by testing to see if this is the last column (single column in the table)
        # or if the cell to the right is bold (multiple columns in the table)
        if  (@oo.last_column == col) || (@oo.cell(row, col+1) && @oo.font(row, col+1).bold?)
          read_header(:row, row)
        end

        # See if this is a row format where the values
        # for each record correspond to spreadsheet columns
        #   *header*, value, value
        #   *header*, value, value
        # 
        # We check this by testing to see if this is the last row (single row in the table)
        # or if the cell below is bold (multiple rows in the table)
        if (@oo.last_row == row) || (@oo.cell(row+1, col) && @oo.font(row+1, col).bold?)
          read_header(:column, col)
          return true
        end

      end
      return false
    end
    
    # Get the header values and set the first and last record indexes
    def read_header(type, index)
      @type = type
      @values = @oo.send(@type, index)
      @values.compact! # we'll get nil records unless the table is left/top justified. May need to be stricter
      @values.map! { |x| x.gsub(/\(\)$/,'') } # we're stripping out () if it's used to clarify methods 
      @first_record = index + 1
      @index = index
      @last_record = @oo.send("last_" + @type.to_s)
    end
  end   
end
