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

