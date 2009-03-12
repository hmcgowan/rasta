class String 
  ARRAY  = /\A\s*\[.+\]\s*\Z/ms
  HASH   = /\A\s*\{.+\}\s*\Z/ms
  BOOL   = /\A\s*(true|false)\s*\Z/i
  REGEXP = /\A\s*(\/.+\/)\w*\s*\Z/ms
  NUMBER = /\A\s*-?\d+\.??\d*?\s*\Z/

  # Given a string, find the closest Ruby data type
  def to_datatype!
    self.strip! if self.class == String
    case self
    when ARRAY, HASH, BOOL, REGEXP
      eval(self)
    when NUMBER
      # if the number starts with 0 and not preceded
      # by a decimal then treat as a string. This 
      # makes sure things like zip codes are properly 
      # handled. Not sure if there's a better way.
      # Otherwise eval to convert to the proper number datatype
      self =~ /^0\d/ ? self : eval(self)  
    else
      self
    end
  end   
end  

module Rasta
  module Spreadsheet
    
    class BookmarkError < RuntimeError; end
    class RecordParseError < RuntimeError; end

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

    def records(oo, opts)
      Records.new(oo, opts)
    end

    class Record
      attr_accessor :name, :header, :values

      # return the cell value at a given header
      def [](x)
        @values[@header.index(x)]
      end
    end
    
    class Records
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
          record.name = record_name(index)
          record.header = header
          record.values = values(index)
          yield record
        end
      end

      def to_a
        result = []
        result << header
        self.each { |record| result << record.values }
        result
      end
      
      def values(x)
        locate_header
        cell_values = []
        cell_values = @oo.send(@oo_record_method_name, x)  # @oo.row(x) or @oo.column(x)
        raise RecordParseError, "No record exists at index #{x}" if cell_values.compact == [] 
        cell_values.map! { |cell| cell.class == String ? cell.to_datatype! : cell  } 
        cell_values
      end
      
      def record_name(x)
        @oo_record_method_name == :row ? x : GenericSpreadsheet.number_to_letter(x)
      end
      private :record_name
      
      def reset_header
        @header_values= nil
        @current_sheet = @oo.default_sheet
      end
      private :reset_header
      
      # Get the header values and set the first and last record indexes
      def read_header(type, index)
        @oo_record_method_name = type
        @header_values = @oo.send(type, index)
        @header_values.compact! # we'll get nil records unless the table is left/top justified. May need to be stricter
        @header_values.map! { |x| x.gsub(/\(\)$/,'') } # we're stripping out () if it's used to clarify methods 
        @first_record = index + 1
        @last_record = @oo.send("last_" + type.to_s)
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