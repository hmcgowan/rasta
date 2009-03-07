specdir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.expand_path(specdir)

require 'spec/spec_helper'
require 'roo'
require 'lib/rasta/spreadsheet'

testfile = File.join(Spreadsheet_dir, 'spreadsheet_parsing.xls')

describe 'rasta_spreadsheet', :shared => true do
  include Rasta::Spreadsheet
end

describe 'spreadsheet_without_options', :shared => true do
  it_should_behave_like 'rasta_spreadsheet'
  before :all do
    @oo = Excel.new(testfile)
    @options = {}
    @records = records(@oo, @options)
    @header = ['a','b']
  end
end

describe 'Locate Column Headers' do
  it_should_behave_like 'spreadsheet_without_options'
  
  it 'should be able to get col headers when flush' do
    @oo.default_sheet = 'col_flush'
    @records.header.should == @header
    @records.style.should == :col
  end
  it 'should be able to get col headers with preceding empty column' do
    @oo.default_sheet = 'col_empty_col'
    @records.header.should == @header
    @records.style.should == :col
  end
  it 'should be able to get col headers with preceding empty row' do
    @oo.default_sheet = 'col_empty_row'
    @records.header.should == @header
    @records.style.should == :col
  end
  it 'should be able to get col headers with preceding empty row and column' do
    @oo.default_sheet = 'col_empty_row_col'
    @records.header.should == @header
    @records.style.should == :col
  end
end

describe 'Locate Row Headers' do   
  it_should_behave_like 'spreadsheet_without_options'

  it 'should be able to get row headers when flush' do
     @oo.default_sheet = 'row_flush'
     @records.header.should == @header
     @records.style.should == :row
   end
   it 'should be able to get row headers with preceding empty row' do
     @oo.default_sheet = 'row_empty_row'
     @records.header.should == @header
     @records.style.should == :row
   end
   it 'should be able to get row headers with preceding empty col' do
     @oo.default_sheet = 'row_empty_col'
     @records.header.should == @header
     @records.style.should == :row
   end
   it 'should be able to get row headers with preceding empty row and column' do
     @oo.default_sheet = 'row_empty_row_col'
     @records.header.should == @header
     @records.style.should == :row
   end
end

describe 'Handle Header Exceptions' do 
  it_should_behave_like 'spreadsheet_without_options'

  it 'should throw an error on an empty sheet when parsing headers' do
    @oo.default_sheet = 'empty_sheet'
    lambda{ @records.header }.should raise_error(Rasta::Spreadsheet::RecordParseError)
  end
  it 'should throw an error on sheet without bold cells' do
    @oo.default_sheet = 'no_headers'
    lambda{ @records.header }.should raise_error(Rasta::Spreadsheet::RecordParseError)
  end
end

describe 'Delegate to Roo for Column Number Mapping' do
  it_should_behave_like 'rasta_spreadsheet'
  
  it 'should map column numbers correctly for single letter' do 
    column_name(1).should == 'A'
  end
  it 'should map column numbers correctly for multiple letters' do 
    column_name(28).should == 'AB'
  end
end

describe 'Convert strings to dataypes' do
   it_should_behave_like 'rasta_spreadsheet'
   
   it 'should trim whitespace' do 
      string_to_datatype('    This is a string   ').should == 'This is a string'
   end
   it 'should convert strings to strings' do 
     string_to_datatype('This is a string').should == 'This is a string'
     string_to_datatype('This is a string]').should == 'This is a string]'
     string_to_datatype('{This is a string').should == '{This is a string'
     string_to_datatype('/This is a string').should == '/This is a string'
   end 
   it 'should handle multiline strings' do
      string_to_datatype("This is a \nstring").should == "This is a \nstring"
      string_to_datatype("This is a \rstring").should == "This is a \rstring"
      string_to_datatype("This is a \r\nstring").should == "This is a \r\nstring"
   end
   it 'should convert arrays' do
     string_to_datatype("['A','B','C']").should == ['A','B','C']
     string_to_datatype("['A','B',['c','d']]").should == ['A','B',['c','d']]
   end
   it 'should convert hashes' do
     string_to_datatype("{:a => 1, :b => 2}").should == {:a => 1, :b => 2}
     string_to_datatype("{:a => 1, :b => 2, :c => {:d => 3}}").should == {:a => 1, :b => 2, :c => {:d => 3}}
   end
   it 'should convert numbers' do
     string_to_datatype('0').should == 0
     string_to_datatype('1').should == 1
     string_to_datatype('1.0').should == 1
     string_to_datatype('0.0').should == 0
     string_to_datatype('0.1').should == 0.1
     string_to_datatype('1.1').should == 1.1
   end
   it 'should convert boolean' do
     string_to_datatype('TRUE').should be_true
     string_to_datatype('true').should be_true
     string_to_datatype('FALSE').should be_false
     string_to_datatype('false').should be_false
   end
   it 'should not convert numbers when integer preceeded by 0' do
     string_to_datatype('01234').should == '01234'
   end
   it 'should convert regex' do
     string_to_datatype('/test/').class.should == Regexp
     string_to_datatype('/test/mx').class.should == Regexp
     string_to_datatype("/test\n/mx").class.should == Regexp
   end
end


# describe "Book Initialization" do
#   it 'should populate the Excel Constants' do
#     # Do this test first or the constants get loaded by Book.new
#     Rasta::Spreadsheet::ExcelConst.constants.should == []
#     book = Rasta::Spreadsheet::Book.new(TESTFILE)
#     Rasta::Spreadsheet::ExcelConst.constants.should_not == []
#   end
#   it 'should fail if file not specified' do
#     lambda {
#       book = Rasta::Spreadsheet::Book.new()
#      }.should raise_error
#   end
#   it 'should fail if file not found' do
#     lambda {
#       book = Rasta::Spreadsheet::Book.new('examples/invalid_file_name')
#      }.should raise_error
#   end
#   it 'should initialize properly with valid filename' do
#     lambda {
#       book = Rasta::Spreadsheet::Book.new(TESTFILE)
#      }.should_not raise_error
#   end
#   it 'should have default options set' do
#     excel = Rasta::Spreadsheet::Excel.instance
#     book = Rasta::Spreadsheet::Book.new(TESTFILE)
#     excel.visible.should be_false
#     excel.continue.should be_false
#   end
#   it 'should handle passed options' do
#     excel = Rasta::Spreadsheet::Excel.instance
#     excel.continue = 'test'
#     book = Rasta::Spreadsheet::Book.new(TESTFILE)
#     excel.visible.should be_false
#     excel.continue.should == 'test'
#     excel.continue = false
#   end
#   it 'should have have a method for returning the filename' do
#     book = Rasta::Spreadsheet::Book.new(TESTFILE)
#     book.filename.should == TESTFILE
#   end
#   it 'should return an ole_object for the workbook' do
#     book = Rasta::Spreadsheet::Book.new(TESTFILE)
#     book.ole_object.class.should == WIN32OLE
#   end
# end
# 
# describe 'SpreadsheetTab', :shared => true do
#   before(:all) do 
#     @book = Rasta::Spreadsheet::Book.new(TESTFILE)
#     @sheet = nil
#   end
#   after(:all) do 
#     Rasta::Spreadsheet::Excel.instance.cleanup 
#   end
# end
# 
# describe 'BasicStyles', :shared => true do
#   it_should_behave_like 'SpreadsheetTab'
#   it 'should locate the headers' do
#     @sheet.headers.should == ['a','b']
#   end
# end
# 
# describe 'Sheet style :col (1)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['ColStyle.1']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 2
#     @sheet.firstcol.should == 1
#     @sheet.lastrow.should  == 7
#     @sheet.lastcol.should  == 2
#   end
# end
# describe 'Sheet style :col (2)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['ColStyle.2']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 2
#     @sheet.firstcol.should == 2
#     @sheet.lastrow.should  == 7
#     @sheet.lastcol.should  == 3
#   end
# end
# describe 'Sheet style :col (3)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['ColStyle.3']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 2
#     @sheet.firstcol.should == 1
#     @sheet.lastrow.should  == 7
#     @sheet.lastcol.should  == 2
#   end
# end
# describe 'Sheet style :col (4)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['ColStyle.4']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 2
#     @sheet.firstcol.should == 2
#     @sheet.lastrow.should  == 7
#     @sheet.lastcol.should  == 3
#   end
# end
# 
# describe 'Sheet style :row (1)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['RowStyle.1']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 1
#     @sheet.firstcol.should == 2
#     @sheet.lastrow.should  == 2
#     @sheet.lastcol.should  == 7
#   end
# end
# describe 'Sheet style :row (2)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['RowStyle.2']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 2
#     @sheet.firstcol.should == 2
#     @sheet.lastrow.should  == 3
#     @sheet.lastcol.should  == 7
#   end
# end
# describe 'Sheet style :row (3)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['RowStyle.3']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 1
#     @sheet.firstcol.should == 2
#     @sheet.lastrow.should  == 2
#     @sheet.lastcol.should  == 7
#   end
# end
# describe 'Sheet style :row (4)' do 
#   it_should_behave_like 'BasicStyles'
#   before(:each) do 
#     @sheet = @book['RowStyle.4']
#   end
#   it 'should find the data range' do
#     @sheet.firstrow.should == 2
#     @sheet.firstcol.should == 2
#     @sheet.lastrow.should  == 3
#     @sheet.lastcol.should  == 7
#   end
# end
# 
# describe 'Datatypes' do
#   it_should_behave_like 'SpreadsheetTab'
#   before(:each) do
#     @sheet = @book['Datatypes']
#   end
#   it 'should handle integers' do
#     @sheet[2][1].value.class.should == Fixnum
#     @sheet[2][1].value.should == 1
#   end
#   it 'should handle floats' do
#     @sheet[2][2].value.class.should == Float
#     @sheet[2][2].value.should == 2.0
#   end
#   it 'should handle hashes' do
#     @sheet[2][3].value.class.should == Hash
#     @sheet[2][3].value.should == { 'a'=>1, 'b'=>2 }
#   end
#   it 'should handle arrays' do
#     @sheet[2][4].value.class.should == Array
#     @sheet[2][4].value.should == ['c', 'd', 'e']
#   end
#   it 'should handle boolean uppercase' do
#     @sheet[2][5].value.class.should == TrueClass
#     @sheet[2][5].value.should == true
#   end
#   it 'should handle boolean lowercase' do
#     @sheet[2][6].value.class.should == FalseClass
#     @sheet[2][6].value.should == false
#   end
# end
# 
# describe 'Whitespace' do
#   it_should_behave_like 'SpreadsheetTab'
#   before(:each) do
#     @sheet = @book['Whitespace']
#   end
#   it 'should trim leading whitespace' do
#     @sheet[2][1].value.should == 'test'
#   end
#   it 'should trim trailing whitespace' do
#     @sheet[2][2].value.should == 'test'
#   end
#   it 'should not trim middle whitespace' do
#     @sheet[2][3].value.should == 'this is a test'
#   end
#   it 'should trim leading and trailing whitespace' do
#     @sheet[2][4].value.should == 'test'
#   end
# end
# 
# describe 'Control Flow - Tabs' do
#   it_should_behave_like 'SpreadsheetTab'
#   it 'should not include hidden tabs' do
#     lambda{ @sheet = @book['ControlFlow.hidden'] }.should raise_error
#   end
#   it 'should not include colored tabs' do
#     lambda{ @sheet = @book['ControlFlow.1'] }.should raise_error
#   end
#   it 'should not include commented tabs' do
#     lambda{ @sheet = @book['ControlFlow.2'] }.should raise_error
#   end
# end
# 
# describe 'Control Flow - Worksheet' do
#   it_should_behave_like 'SpreadsheetTab'
#   it 'should select worksheet without error' do
#     lambda{ 
#       @sheet = @book['ColStyle.1'] #select called implicitly
#      }.should_not raise_error
#   end
#   it 'should raise error when calling bogus worksheet' do
#     lambda{ 
#       @sheet = @book['Bogus'] #select called implicitly
#     }.should raise_error
#   end
#   it 'should select the home cell without error' do
#     @sheet = @book['ColStyle.1']
#     lambda{ @sheet.select_home_cell }.should_not raise_error
#   end
#   it 'should properly identify data cells' do
#     @sheet = @book['ColStyle.1']
#     @sheet.datacell?(1,1).should == false
#     @sheet.datacell?(1,2).should == false
#     @sheet.datacell?(2,1).should == true
#     @sheet.datacell?(2,2).should == true
#   end
#   it 'should be able to get a range for a :row style' do
#     @sheet = @book['ColStyle.1']
#     lambda{ @sheet.cellrange(2) }.should_not raise_error
#   end
#   it 'should be able to get a range of cell values for a :row style' do
#     @sheet = @book['ColStyle.1']
#     @sheet.cellrangevals(2).should == [1.0,2.0]
#   end
#   it 'should be able to get a range for a :col style' do
#     @sheet = @book['RowStyle.1']
#     @sheet.cellrangevals(2).should == [1.0,2.0]
#   end
#   it 'should be able to get a worksheet column name from a column index' do
#     @sheet = @book['ColStyle.1']
#     @sheet.colname(1).should == 'A'
#     @sheet.colname(2).should == 'B'
#   end
#   it 'should gracefully handle a sheet with no data' do
#     @sheet = @book['Blank']
#     lambda{ @sheet.cellrange(2) }.should_not raise_error
#   end
# end
# 
# describe 'Sheet initialization' do 
#   it_should_behave_like 'SpreadsheetTab'
# 
#   it 'should provide the reference to the Book' do
#     @book['ColStyle.1'].book.class.should == Rasta::Spreadsheet::Book
#   end
# 
#   it 'should return a valid ole_object for the Sheet' do
#     @book['ColStyle.1'].ole_object.class.should == WIN32OLE
#   end
# 
#   it 'should return the name of the worksheet tab' do
#     @book['ColStyle.1'].name.should == 'ColStyle.1'
#   end
# 
#   it 'should provide metadata with to_s' do
#     metadata = "firstrow = 2\n" + 
#                "firstcol = 1\n" +
#                "lastrow  = 7\n" +
#                "lastcol  = 2\n" +
#                "style    = row\n"
#     @book['ColStyle.1'].to_s.should == metadata
#   end
# end
# 
# # Apparently the WIN32OLE returns a string for a range 
# # with a single value and an array for multiple values
# # so test for the corner case. This series of tests
# # makes sure we can properly handle a spreadsheet
# # with that single data cell
# describe 'Single data cell' do 
#   it_should_behave_like 'SpreadsheetTab'
# 
#   it 'should properly identify data cells for :col' do
#     @sheet = @book['SingleCell.col']
#     @sheet.datacell?(2,1).should == true
#   end
#   it 'should get data from cell for :col' do
#     @sheet = @book['SingleCell.col']
#     @sheet.headers.should == ['number']
#   end
#   it 'should be able to get a range for a :col style' do
#     @sheet = @book['SingleCell.col']
#     lambda{ @sheet.cellrangevals(2) }.should_not raise_error
#   end
#   it 'should properly identify data cells for :row' do
#     @sheet = @book['SingleCell.row']
#     @sheet.datacell?(1,2).should == true
#   end
#   it 'should get data from cell for :row' do
#     @sheet = @book['SingleCell.row']
#     @sheet.headers.should == ['number']
#   end
#   it 'should be able to get a range for a :row style' do
#     @sheet = @book['SingleCell.row']
#     lambda{ @sheet.cellrangevals(2) }.should_not raise_error
#   end
# end
