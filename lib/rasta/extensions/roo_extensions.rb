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

  class RecordCell
    attr_accessor :name, :value, :header

    def initialize(row, col, oo, header)
      @oo = oo
      @header = header
      @name = cell_name(row, col)
      @value = cell_value(row, col)
    end
    
    def empty?
      (value.nil? || value == '' || header.nil? || header == '') ? true : false
    end
    
  private
  
    def cell_value(row, col)
      if @oo.font(row,col).italic?
        value = nil
      else 
        value = @oo.cell(row,col)
        value = value.to_datatype if String === value 
      end
      value.postprocess 
    end    
    
    def cell_name(row, col)
      GenericSpreadsheet.number_to_letter(col) + row.to_s
    end
    
  end
  
  class Record
    attr_accessor :cells, :header, :name, :type

    def initialize(type, index, oo, header)
      @cells = []
      @type = type
      @name = index
      @oo = oo
      @header = header
      @first_cell = @oo.send('first_' + @type.to_s)
      @last_cell = @oo.send('last_' + @type.to_s)
      create_record(index)
    end
    
    def each
      @cells.each { |x| yield x }
    end 
    
    # return the cell value at a given header
    def [](x)
      case x
      when String
        begin
          @cells[@header.values.index(x)]
        rescue TypeError
          raise RangeError, "No header value exists for: #{x}"
        end
      when Integer  
        @cells[x]
      end
    end
    
    def to_a
      result = []
      @cells.each {|c| result << c.value }
      result 
    end
    
    def create_record(idx)
      (@first_cell..@last_cell).each do |cell_index|
        if @type == :row
          row = cell_index
          col = idx
        else
          row = idx
          col = cell_index
        end
        @cells << RecordCell.new(row, col, @oo,  @header.values[cell_index-1])
      end
    end    
  end
  
  class Records
    
    def initialize(oo, sheet)
      @oo = oo
      @oo.default_sheet = sheet if sheet
      @type = nil
      @record_list = []
      @header = RecordHeader.new(@oo)
      @type = record_type
      @records = []
      read_records
    end
    
    def type; @header.type; end
    def header; @header.values; end
    def header_index; @header.index; end
    
    def each(&block)
      @records.each { |x| yield x }
    end

    def [](x)
      raise RangeError, "Record #{x} out of range" unless @records[x]
      @records[x]
    end
    
    def to_a
      result = []
      @records.each { |x| result << x.to_a }
      result
    end
    
    def read_records
      (@header.first_record..@header.last_record).each { |index| @records << Record.new(@type, index, @oo, @header) }
    end
    
    def record_type
      @header.type == :row ? :column : :row 
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
