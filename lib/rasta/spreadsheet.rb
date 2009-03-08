module Rasta
  module Spreadsheet
    
    class BookmarkError < RuntimeError; end
    class RecordParseError < RuntimeError; end

    def records(oo, opts)
      Records.new(oo, opts)
    end

    module Utils
      ARRAY  = /\A\s*\[.+\]\s*\Z/ms
      HASH   = /\A\s*\{.+\}\s*\Z/ms
      BOOL   = /\A\s*(true|false)\s*\Z/i
      REGEXP = /\A\s*(\/.+\/)\w*\s*\Z/ms
      NUMBER = /\A\s*-?\d+\.??\d*?\s*\Z/

      # Delegate to roo for mapping col number to letters
      def column_name(x)
        GenericSpreadsheet.number_to_letter(x)
      end
    
      # Given a string, find the closest Ruby data type
      def string_to_datatype(x)
        x.strip! if x.class == String
        case x
        when ARRAY, HASH, BOOL, REGEXP
          eval(x)
        when NUMBER
          # if the number starts with 0 and not preceded
          # by a decimal then treat as a string. This 
          # makes sure things like zip codes are properly 
          # handled. Not sure if there's a better way.
          # If not that case, then eval to convert to the proper
          # number datatype
          x =~ /^0\d/ ? x : eval(x)  
        else
          x
        end
      end   
    end  
    
    # A single record which represents a row or column
    # of the spreadsheet wih the header values for that record
    class Record
      attr_accessor :header, :values
      
      def initialize(header, cell_values)
        @header = header
        @values = cell_values
      end

      def [](x)
        @values[@header.index(x)]
      end
      
    end
    
    # Access to the records of a given spreadsheet
    class Records
      include Utils
      attr_reader :style

      def initialize(oo, opts)
        @oo = oo
        @bookmark = Bookmark.new(opts)
        @bookmark.page_count += 1
      end
      
      def each(&block)
        locate_header
        case @style
        when :row
          ((@header_index + 1)..@oo.last_column).each do |index|
            next if !@bookmark.found_record?(index)
            @bookmark.record_count += 1
            return if @bookmark.exceeded_max_records?
            yield Record.new(header, values(index))
          end
        when :col
          ((@header_index + 1)..@oo.last_row).each do |index|
            next if !@bookmark.found_record?(column_name(index))
            @bookmark.record_count += 1
            return if @bookmark.exceeded_max_records?
            yield Record.new(header, values(index))
          end
        else 
          raise RuntimeError, "No style set for #{@oo.default_sheet}"
        end
      end
      
      def header
        locate_header 
        @header_values
      end

      # Return the values for a given row or col
      def values(x)
        locate_header
        cell_values = []
        case @style
        when :row
          cell_values = @oo.column(x)
        when :col
          cell_values = @oo.row(x)
        end
        raise RecordParseError, "No record exists at #{@style} #{x}" if cell_values.compact == [] 
        cell_values.map! do |cell| 
          cell = string_to_datatype(cell) 
        end
        cell_values
      end
      
      def dump
        result = []
        result << header
        self.each do |record|
          result << record.values
        end
        result
      end
      
      # Find the header by parsing the spreadsheet and auto-detecting
      # if it's a row or column fixture layout. 
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
        raise RecordParseError, "Unable to locate header row for #{@oo.default_sheet}" unless @style && @header_index > 0
      end    
      private :locate_header
      
      # If we've detected that we're on a new sheet, 
      # reset the internal state
      def reset_header
        @style = nil
        @header_index = 0
        @header_values= nil
        @current_sheet = @oo.default_sheet
      end
      private :reset_header
      
      def found_header?(row, col)
        return true if @header_values
        method_parens = /\(\)$/ # we're stripping out () if it's used to clarify methods 
        if @oo.font(row,col).bold?
          if @oo.empty?(row, col+1) || ( @oo.cell(row, col+1) && @oo.font(row, col+1).bold? )
            @style = :col
            @header_index = row
            @header_values = @oo.row(row).compact.map { |x| x.gsub(method_parens,'') }
            return true
          elsif  @oo.empty?(row+1, col) || ( @oo.cell(row+1, col) && @oo.font(row+1, col).bold? )
            @style = :row
            @header_index = col
            @header_values = @oo.column(col).compact.map { |x| x.gsub(method_parens,'') }
            return true
          end
        end
        return false
      end
      private :found_header?
      
    end
    
    class Bookmark
      attr_accessor :page_count, :record_count, :continue

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
        if name =~ /^([^\[]+)(\[(\S+)\])?/
          pagename = $1
          recordid = $3.upcase if $3
          return pagename, recordid
        else
          raise BookmarkError, "Invalid bookmark '#{name}'" 
        end  
      end
    end
   
  end  
end