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
    attr_accessor :name, :value, :raw_value, :italic, :header

    def initialize(oo, row, col)
      @italic = false
      @oo = oo
      @name = GenericSpreadsheet.number_to_letter(col) + row.to_s
      @value = nil
      @raw_value = @oo.cell(row,col)
      @italic = (@raw_value && @oo.font(row,col).italic?) ? true : false
      initialize_value
    end
    
    def empty?
      (@value.nil? || @value == '' || @italic) ? true : false
    end
    
  private
  
    def initialize_value
      return if @italic
     
      begin
        @value = (String === @raw_value) ? @raw_value.to_datatype : @raw_value
      rescue SyntaxError   # find out better way to handle - not trapped by rescue
        @value = @raw_value
      rescue
        @value = @raw_value
      end
      
      @value = @value.postprocess 
    end    
    
  end
  
  class Record
    attr_accessor :cells, :header, :index, :type

    def initialize(type, index, oo, header)
      @cells = []
      @type = type
      @index = index
      @oo = oo
      @header = header
      create_record
    end
    
    def name
      type == :row ? GenericSpreadsheet.number_to_letter(@index) : @index.to_s
    end
    
    def each
      @cells.each { |x| yield x }
    end 
    
    # return the cell value at a given header
    def [](x)
      case x
      when String
        raise RangeError, "No header value exists for: #{x}" unless @header.include?(x)
        @cells[@header.values.index(x)]
      when Integer 
        raise RangeError, "No header value exists for: #{x}" if x > @header.values.length - 1
        @cells[x]
      else  
        raise RangeError, "Don't know how to handle: #{x}, #{x.class}" 
      end
    end
    
    def to_a
      result = []
      @cells.each {|c| result << c.value }
      result 
    end
    
    def empty?
      @cells.each{|x| return false unless x.empty?}
      true
    end
    
  private 
    
    def create_record
      @header.each_index do |header_index|
        if @type == :row
          row = header_index
          col = @index
        else
          row = @index
          col = header_index
        end
        cell = RecordCell.new(@oo, row, col)
        cell.header = @header[header_index]
        @cells << cell
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
    
    def each
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

  private 
      
    def read_records
      (@header.first_record..@header.last_record).each do |index|
        next_record = Record.new(@type, index, @oo, @header)  
        return if next_record.empty?
        @records << next_record
      end
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
    
    def include?(x)
      @values.include?(x)
    end
    
    def each_index
      (@index..(@index + @values.size - 1)).each { |x| yield x}
    end
    
    def [](x)
      @values[x-@index]
    end
    private
    
    # Find the header by scanning the spreadsheet and
    # testing each cell until we've found the header
    def locate
      return if (@oo.default_sheet == @current_sheet) 
      @values = nil
      @current_sheet = @oo.default_sheet
      each_cell do |row, col|
        next if @oo.empty?(row,col)
        return if found_header?(row,col)
      end
      raise RecordParseError, "Unable to locate header row for #{@oo.default_sheet}" unless @values
    end    
    
    def each_cell
      return unless (@oo.last_row && @oo.last_column)
      (1..@oo.last_row).each do |row|
        (1..@oo.last_column).each do |col|
          yield row, col
        end     
      end
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
      @values = header_values(index)
      @first_record = index + 1
      @index = index
      @last_record = @oo.send("last_" + @type.to_s)
    end
    
    def header_values(index)
      values = @oo.send(@type, index)
      # Strip out any leading nil values
      values.shift while (values.size > 0 && values[0] == nil)
      # Strip out any values after and including a nil value
      if values.index(nil)
        values = values[0..values.index(nil) -1]
      end
      # Remove any camel-case in front of the headers (undocumented feature :) )  
      values.shift while values[0] =~ /A-Z/ 
      raise RecordParseError, "No header values found for sheet #{@oo.default_sheet}" unless values.size > 0
      values.map! { |x| x.gsub(/\(\)$/,'') } # strip out () if it's used to clarify methods 
      values
    end
  end   
end

