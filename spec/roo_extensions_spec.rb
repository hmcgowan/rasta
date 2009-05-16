# lib_dir = File.join(File.dirname(__FILE__), '..')
# $LOAD_PATH.unshift File.expand_path(lib_dir)

# require 'spec/spec_helper'
# 
# # TODO: update this since we're requiring roo now
# describe 'Roo Extensions' do
#   before :all do
#     Object.constants.delete('Google') if Object.constants.member?('Google')
#     class GenericSpreadsheet; end
#     require 'rasta/extensions/roo_extensions'
#     @oo = Google.new
#   end
#   it 'should implement a font interface for Google docs' do
#     @oo.font(2,1).class.should == Google::Font
#   end
#   it 'should see the first column as bold (forces column fixture)' do
#     @oo.font(2,1).bold?.should == true
#   end
#   it 'should see the any other column as normal' do
#     @oo.font(2,2).bold?.should == false
#   end
# end

Root_dir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.expand_path(Root_dir)

require 'spec/spec_helper'
require 'roo'
require 'lib/rasta/extensions/roo_extensions'

testfile = File.join(Spreadsheet_dir, 'spreadsheet_parsing.xls')

describe 'rasta_spreadsheet', :shared => true do
  include Roo::Spreadsheet
end

describe 'spreadsheet_without_options', :shared => true do
  it_should_behave_like 'rasta_spreadsheet'
  before :all do
    @oo = Excel.new(testfile)
    @options = {}
    @records = @oo.records(@options)
    @header = ['a','b']
  end
end

describe 'Locate Column Headers' do
  it_should_behave_like 'spreadsheet_without_options'
  
  it 'should be able to get col headers when flush' do
    @oo.default_sheet = 'col_flush'
    @records.header.should == @header
  end
  it 'should be able to get col headers with preceding empty column' do
    @oo.default_sheet = 'col_empty_col'
    @records.header.should == @header
  end
  it 'should be able to get col headers with preceding empty row' do
    @oo.default_sheet = 'col_empty_row'
    @records.header.should == @header
  end
  it 'should be able to get col headers with preceding empty row and column' do
    @oo.default_sheet = 'col_empty_row_col'
    @records.header.should == @header
  end
end

describe 'Locate Row Headers' do   
  it_should_behave_like 'spreadsheet_without_options'

  it 'should be able to get row headers when flush' do
     @oo.default_sheet = 'row_flush'
     @records.header.should == @header
   end
   it 'should be able to get row headers with preceding empty row' do
     @oo.default_sheet = 'row_empty_row'
     @records.header.should == @header
   end
   it 'should be able to get row headers with preceding empty col' do
     @oo.default_sheet = 'row_empty_col'
     @records.header.should == @header
   end
   it 'should be able to get row headers with preceding empty row and column' do
     @oo.default_sheet = 'row_empty_row_col'
     @records.header.should == @header
   end
end

describe 'Handle Header Exceptions' do 
  it_should_behave_like 'spreadsheet_without_options'

  it 'should throw an error on an empty sheet when parsing headers' do
    @oo.default_sheet = 'empty_sheet'
    lambda{ @records.header }.should raise_error(Roo::Spreadsheet::RecordParseError)
  end
  it 'should throw an error on sheet without bold cells' do
    @oo.default_sheet = 'no_header'
    lambda{ @records.header }.should raise_error(Roo::Spreadsheet::RecordParseError)
  end
  it 'should throw an error on sheet without valid header cells' do
    @oo.default_sheet = 'invalid_header'
    lambda{ @records.header }.should raise_error(Roo::Spreadsheet::RecordParseError)
  end
end

describe 'Convert strings to dataypes' do
   it_should_behave_like 'rasta_spreadsheet'
   
   it 'should trim whitespace' do 
     '    This is a string   '.to_datatype!.should == 'This is a string'
   end
   it 'should convert strings to strings' do 
     'This is a string'.to_datatype!.should == 'This is a string'
     'This is a string]'.to_datatype!.should == 'This is a string]'
     '{This is a string'.to_datatype!.should == '{This is a string'
     '/This is a string'.to_datatype!.should == '/This is a string'
   end 
   it 'should handle multiline strings' do
      "This is a \nstring".to_datatype!.should == "This is a \nstring"
      "This is a \rstring".to_datatype!.should == "This is a \rstring"
      "This is a \r\nstring".to_datatype!.should == "This is a \r\nstring"
   end
   it 'should convert arrays' do
     "['A','B','C']".to_datatype!.should == ['A','B','C']
     "['A','B',['c','d']]".to_datatype!.should == ['A','B',['c','d']]
   end
   it 'should convert hashes' do
     "{:a => 1, :b => 2}".to_datatype!.should == {:a => 1, :b => 2}
     "{:a => 1, :b => 2, :c => {:d => 3}}".to_datatype!.should == {:a => 1, :b => 2, :c => {:d => 3}}
   end
   it 'should convert numbers' do
     '0'.to_datatype!.should == 0
     '1'.to_datatype!.should == 1
     '1.0'.to_datatype!.should == 1
     '0.0'.to_datatype!.should == 0
     '0.1'.to_datatype!.should == 0.1
     '1.1'.to_datatype!.should == 1.1
   end
   it 'should convert boolean' do
     'TRUE'.to_datatype!.should be_true
     'true'.to_datatype!.should be_true
     'FALSE'.to_datatype!.should be_false
     'false'.to_datatype!.should be_false
   end
   it 'should not convert numbers when integer preceeded by 0' do
     '01234'.to_datatype!.should == '01234'
   end
   it 'should convert regex' do
     '/test/'.to_datatype!.class.should == Regexp
     '/test/mx'.to_datatype!.class.should == Regexp
     "/test\n/mx".to_datatype!.class.should == Regexp
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
    @records.values(2).should == [1]
  end
  it 'should be able to parse a sheet with a single row record' do
    @oo.default_sheet = 'single_cell_row'
    @records.header.should == ['number']
    @records.values(2).should == [1]
  end
  it 'should raise an exception if the row/col does not exist' do
    @oo.default_sheet = 'single_cell_row'
    lambda{ @records.values(3) }.should raise_error(Roo::Spreadsheet::RecordParseError)
  end
end


describe 'Dump records' do
  it_should_behave_like 'spreadsheet_without_options'

  it 'should be able to get all of the records for a col record' do
    @oo.default_sheet = 'col_flush'
    @records.to_a.should == [["a", "b"], [1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
  it 'should be able to get all of the records for a row record' do
    @oo.default_sheet = 'row_flush'
    @records.to_a.should == [["a", "b"], [1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
end

describe 'Iterate over records' do
  it_should_behave_like 'spreadsheet_without_options'
# @oo.header
# @oo.first_record
  it 'should be able to get all of the records for a col record' do
    @oo.default_sheet = 'row_flush'
    @oo.records.each do |record|
      record.each do |cell|
        puts cell.value
        puts cell.name
        puts cell.header
      end
    end
    #@records.to_a.should == [["a", "b"], [1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
  it 'should be able to get all of the records for a row record' do
    @oo.default_sheet = 'row_flush'
    @records.to_a.should == [["a", "b"], [1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
end

describe 'Spreadsheet comments' do
  it 'should ignore comments'
end

