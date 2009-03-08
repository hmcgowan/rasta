specdir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.expand_path(specdir)

require 'spec/spec_helper'
require 'roo'
require 'lib/rasta/spreadsheet'

testfile = File.join(Spreadsheet_dir, 'spreadsheet_parsing.xls')

describe 'rasta_spreadsheet', :shared => true do
  include Rasta::Spreadsheet
  include Rasta::Spreadsheet::Utils
  
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

describe 'Get record values' do
    it_should_behave_like 'spreadsheet_without_options'
    
    it 'should be able to parse a col record' do
      @oo.default_sheet = 'col_flush'
      @records.values(2).should == [1.0, 2.0]
    end
    it 'should be able to parse a row record' do
      @oo.default_sheet = 'row_flush'
      @records.values(2).should == [1.0, 2.0]
    end
end

describe 'Small datasets' do
  it_should_behave_like 'spreadsheet_without_options'
  
  it 'should be able to parse a sheet with a single col record' do
    @oo.default_sheet = 'single_cell_col'
    @records.header.should == ['number']
    @records.style.should == :col
    @records.values(2).should == [1]
  end
  it 'should be able to parse a sheet with a single row record' do
    @oo.default_sheet = 'single_cell_row'
    @records.header.should == ['number']
    @records.style.should == :row
    @records.values(2).should == [1]
  end
  it 'should raise an exception if the row/col does not exist' do
    @oo.default_sheet = 'single_cell_row'
    lambda{ @records.values(3) }.should raise_error(Rasta::Spreadsheet::RecordParseError)
  end
end


describe 'Iterate over records' do
  it_should_behave_like 'spreadsheet_without_options'

  it 'should be able to get all of the records for a col record' do
    @oo.default_sheet = 'col_flush'
    @records.dump.should == [["a", "b"], [1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
  it 'should be able to get all of the records for a row record' do
    @oo.default_sheet = 'row_flush'
    @records.dump.should == [["a", "b"], [1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
end

