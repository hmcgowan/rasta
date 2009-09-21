module Rasta

  class BookmarkError < RuntimeError; end
  
  class Bookmark
    attr_accessor :page_count, :max_page_count, :page, :record
    attr_accessor :record_count, :max_record_count, :bookmark

    def initialize(options = {})
      @page_count = 0
      @record_count = 0
      @max_page_count = options[:pages] || 0
      @max_record_count = options[:records] || 0
      @bookmark = options[:bookmark] unless (@bookmark && @bookmark.empty?)
      initialize_finders
      read_bookmark if @bookmark
    end

    def initialize_finders
      if @bookmark
        @found_page = false
        @found_record = false
      else
        # No bookmark exists so act as if the first page and
        # record is the bookmark so all records are seen
        @found_page = true
        @found_record = true
      end  
    end    

    def read_bookmark
      if @bookmark =~ /^([^\[]+)(\[(\S+)\])?/
        self.page = $1
        self.record = $3
      else
        raise BookmarkError, "Invalid bookmark name '#{@bookmark}'" 
      end
    end

    def page=(x)
      @page = x
    end  
    
    def record=(x)
      @record = x
      case @record
      when bookmark_column
        @record = GenericSpreadsheet.letter_to_number(@record)
      when bookmark_row  
        @record = @record.to_i
      when nil
        @found_record = true # no record specified, but valid bookmark
      else
        raise BookmarkError, "Invalid record #{x} for bookmark '#{@bookmark}'" 
      end   
    end
    
    def bookmark_column
      /\A[a-z]+\Z/i 
    end
    
    def bookmark_row
      /\A\d+\Z/ 
    end
    
    def page_name
      @page =~ /^([^#]+)/
      $1
    end

    def exists?(roo)
      roo.sheets.include?(page_name)
    end
    
    def found_page?(page)
      if @found_page || page == @page 
        @found_page = true
        @page_count += 1 
        true
      else
        false
      end
    end
  
    def found_record?(record)
      if @found_record || record == @record
        @found_record = true 
        @record_count += 1 
        true
      else 
        false
      end
    end
  
    def exceeded_max_records?
      if @max_record_count == 0 and @max_page_count == 0
        false
      elsif (@record_count > @max_record_count) and @max_record_count > 0
        true
      elsif (@page_count > @max_page_count) and @max_page_count > 0
        true
      else  
        false
      end  
    end
    
  end
end