require 'roo'
require 'rasta/extensions/ruby_extensions'

module Roo
  module Spreadsheet
    
    # Using the file extension, open the 
    # spreadsheet with the right roo method
    def self.open(filename)
      case File.extname(filename)
      when '.xls'
        Excel.new(filename)
      when '.xlsx'
        Excelx.new(filename)
      when '.ods'
        Openoffice.new(filename)
      when ''
        Google.new(filename)
      else
        raise ArgumentError, "Don't know how to handle spreadsheet #{filename}"
      end        
    end
    
    class BookmarkError < RuntimeError; end
    class RecordParseError < RuntimeError; end

    class RecordCell
      attr_accessor :name, :value, :header
      def initialize(name, value, header)
        @name = name
        @value = value
        @header = header
      end
    end
    
    class Record
      attr_accessor :sheet, :record_cells, :header

      def each
        @record_cells.each { |cell| yield cell }
      end 
      
      # return the cell value at a given header
      def [](x)
        case x
        when String
          @record_cells[@header.index(x)]
        when Integer  
          @record_cells[x]
        end
      end
      
      def to_h
        result = {}
        @header.each {|h| result[h] = self[h] }
        result 
      end
    end
    
    class Records
      attr_accessor :type, :first_record, :last_record
      
      def initialize(oo, opts)
        @oo = oo
        @bookmark = Bookmark.new(opts)
        @bookmark.page_count += 1
      end
      
      def header
        locate_header 
        @header_values
      end

      def each(&block)
        return unless @bookmark.found_page?(@oo.default_sheet)
        locate_header
        (@first_record..@last_record).each do |index|
          next if !@bookmark.found_record?(index)
          @bookmark.record_count += 1
          return if @bookmark.exceeded_max_records?
          record = Record.new
          record.sheet = @oo.default_sheet
          record.header = @header_values
          record.record_cells = record_cells(index)
          yield record
        end
      end

      def to_a
        result = []
        result << header
        self.each { |record| result << record.values }
        result
      end
      
      def to_h
        result = []
        self.each { |record| result << record.to_h }
        result
      end
      
      def record_cells(x)
        locate_header
        record_values = []
        record_values = @oo.send(@type, x)  # @oo.row(x) or @oo.column(x)
        raise RecordParseError, "No record exists at index #{x}" if record_values.compact == [] 
        cells = []
        idx = @first_record - 1
        record_values.each do |val|
          val = val.to_datatype if val.class == String
          name = nil
          if @type == :row
            name = GenericSpreadsheet.number_to_letter(idx) + x.to_s
            header = @header_values[idx-1]
          else
            name = GenericSpreadsheet.number_to_letter(x) + idx.to_s
            header = @header_values[idx-1]
          end
          cells << RecordCell.new(name, val, header)
          idx += 1
        end
        cells
      end
      
      def reset_header
        @header_values= nil
        @current_sheet = @oo.default_sheet
      end
      private :reset_header
      
      # Get the header values and set the first and last record indexes
      def read_header(type, index)
        @type = type
        @header_values = @oo.send(@type, index)
        @header_values.compact! # we'll get nil records unless the table is left/top justified. May need to be stricter
        @header_values.map! { |x| x.gsub(/\(\)$/,'') } # we're stripping out () if it's used to clarify methods 
        @first_record = index + 1
        @last_record = @oo.send("last_" + @type.to_s)
      end
      private :read_header

      # Find the header by scanning the spreadsheet and
      # testing each cell until we've found the header
      def locate_header
        return if (@oo.default_sheet == @current_sheet) && @header_values
        reset_header
        if @oo.last_row && @oo.last_column
          (1..@oo.last_row).each do |row|
            (1..@oo.last_column).each do |col|
              next if @oo.empty?(row,col)
              return if found_header?(row,col)
            end     
          end
        end
        raise RecordParseError, "Unable to locate header row for #{@oo.default_sheet}" unless @header_values
      end    
      private :locate_header
      
      def found_header?(row, col)
        return true if @header_values
        
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
      private :found_header?
      
    end
    
    class Bookmark
      attr_accessor :page_count, :max_page_count
      attr_accessor :record_count, :max_record_count, :continue

      def initialize(options = {})
        @continue = false
        @page_count = 0
        @record_count = 0
        @max_page_count = options[:pages] || 0
        @max_record_count = options[:records] || 0
        read(options)
      end
      
      def found_page?(page)
        return true if @found_bookmark_page
        @found_bookmark_page = true if page == @bookmark_page 
        @found_bookmark_page || false
      end
      
      def found_record?(record)
        return true if @found_bookmark_record 
        @found_bookmark_record = true if record == @bookmark_record
        @found_bookmark_record || false
      end
      
      def exceeded_max_records?
        return false if @max_record_count == 0 and @max_page_count == 0
        return true if (@record_count > @max_record_count) and @max_record_count > 0
        return true if (@page_count > @max_page_count) and @max_page_count > 0
        return false
      end
    
      def read(options)
        if options[:continue]
          @continue = true 
          @bookmark_page, @bookmark_record = parse_bookmark(options[:continue])
          @found_bookmark_record = true unless @bookmark_record
        else
          @found_bookmark_page = true
          @found_bookmark_record = true
        end  
      end

      def parse_bookmark(name)
        valid_bookmark_format = /^([^\[]+)(\[(\S+)\])?/
        column_record = /\A[a-z]+\Z/i 
        row_record = /\A\d+\Z/ 
        return [nil,nil] if name.nil?
        if name =~ valid_bookmark_format
          pagename = $1
          record = $3
          case record
          when column_record
            record = GenericSpreadsheet.letter_to_number(record)
          when row_record  
            record = record.to_i
          when nil
            # no record set, which is fine
          else
            raise BookmarkError, "Invalid record name for bookmark '#{name}'" 
          end   
          return pagename, record
        else
          raise BookmarkError, "Invalid bookmark name '#{name}'" 
        end  
      end
    end
   
  end  
end

class GenericSpreadsheet
  def records(opts={})
    Roo::Spreadsheet::Records.new(self, opts)
  end
end

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
