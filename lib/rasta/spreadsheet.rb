module Rasta
  module Spreadsheet
    ARRAY        = /\A\s*\[.+\]\s*\Z/ms
    HASH         = /\A\s*\{.+\}\s*\Z/ms
    BOOL         = /\A\s*(true|false)\s*\Z/i
    REGEXP       = /\A\s*(\/.+\/)\s*\Z/ms
    NUMBER       = /\A\s*-?\d+\.??\d*?\s*\Z/
    
    def records(oo)
      Records.new(oo)
    end
    
    class Record
      attr_accessor :headers, :values
      
      def initialize(header_values, cell_values)
        @headers = header_values
        @values = cell_values
      end

      def [](x)
        @values[@headers.index(x)]
      end
      
    end
    
    class Records
      def initialize(oo)
        @oo = oo
        Bookmark.page_count += 1
      end
      
      def each(&block)
        @headers ||= locate_headers
        case @style
        when :row
          ((@header_index + 1)..@oo.last_row).each do |index|
            next if !Bookmark.found_record?(index)
            Bookmark.record_count += 1
            return if Bookmark.exceeded_max_records?
            yield Record.new(@headers, values(index))
          end
        when :col
          ((@header_index + 1)..@oo.last_column).each do |index|
            next if !Bookmark.found_record?(column_name(index))
            Bookmark.record_count += 1
            return if Bookmark.exceeded_max_records?
            yield Record.new(@headers, values(index))
          end
        else 
          raise RuntimeError, "No style set for #{@oo.default_sheet}"
        end
      end
      
      def locate_headers
        @header_index = 0
        @style = nil
        (1..@oo.last_row).each do |row|
          (1..@oo.last_column).each do |col|
            if @oo.cellformat(row,col).bold?
              if @oo.cellformat(row+1, col).bold?
                @style = :col
                @header_index = col
                return @oo.column(col).compact
              elsif @oo.cellformat(row, col+1).bold?
                @style = :row
                @header_index = row
                return  @oo.row(row).compact
              end
            end
          end     
        end
        raise RuntimeError, "Unable to locate header row for #{@oo.default_sheet}" unless @style && @header_index > 0
      end    
      
      def values(x)
        case @style
        when :row
          cell_values = @oo.row(x)
        when :col
          cell_values = @oo.column(x)
        end
        cell_values = cell_values[@header_index-1..cell_values.size-1]
        cell_values.map! do |cell| 
          cell = convert_to_datatype(cell) 
        end
        cell_values
      end
      
      def convert_to_datatype(x)
        x.strip! if x.class == String
        case x
        when ARRAY, HASH, BOOL, REGEXP
          eval(x)
        when NUMBER
          eval(x) unless x =~ /^0\d/ 
        else
          x
        end
      end     
      
      # Convert a column index to column letter
      # using roo's method
      def column_name(x)
        GenericSpreadsheet.number_to_letter(x)
      end
    end
    
    
    
    class Bookmark

      class << self
        attr_accessor :page_count, :record_count, :continue
        
        def found_page?(page)
          return true if @found_bookmark_page
          @found_bookmark_page = true if page == @bookmark_page 
          @found_bookmark_page
        end
        
        def found_record?(record)
          return true if @found_bookmark_record 
          @found_bookmark_record = true if record == @bookmark_record
          @found_bookmark_record
        end
        
        def exceeded_max_records?
          return false if @max_record_count == 0 and @max_page_count == 0
          return true if (@record_count > @max_record_count) and @max_record_count > 0
          return true if (@page_count > @max_page_count) and @max_page_count > 0
          return false
        end
      
        def read(options)
          @continue = false
          @page_count = 0
          @record_count = 0
          @max_page_count = options[:pages] || 0
          @max_record_count = options[:records] || 0
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
          name =~ /([^\[]+)(\[(\S+)\])?/
          pagename = $1
          recordid = $3.upcase if $3
          return pagename, recordid
        end
      end

    end
    

  end  
end