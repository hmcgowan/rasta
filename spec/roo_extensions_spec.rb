require File.join(File.dirname(__FILE__), 'spec_helper')

require 'roo'
require 'rasta/extensions/roo_extensions'

testfile = File.join(Test::Spreadsheet_dir, 'spreadsheet_parsing.xls')

describe 'rasta_spreadsheet', :shared => true do
end

describe 'spreadsheet', :shared => true do
  it_should_behave_like 'rasta_spreadsheet'
  before :all do
    @oo = Excel.new(testfile)
    @header = ['a','b']
  end
end

describe 'Locate Column Headers' do
  it_should_behave_like 'spreadsheet'
  
  it 'should be able to get col headers when flush' do
    @oo.default_sheet = 'col_flush'
    @oo.records.header.should == @header
  end
  it 'should be able to get col headers with preceding empty column' do
    @oo.default_sheet = 'col_empty_col'
    @oo.records.header.should == @header
  end
  it 'should be able to get col headers with preceding empty row' do
    @oo.default_sheet = 'col_empty_row'
    @oo.records.header.should == @header
  end
  it 'should be able to get col headers with preceding empty row and column' do
    @oo.default_sheet = 'col_empty_row_col'
    @oo.records.header.should == @header
  end
end

describe 'Locate Row Headers' do   
  it_should_behave_like 'spreadsheet'

  it 'should be able to get row headers when flush' do
     @oo.default_sheet = 'row_flush'
     @oo.records.header.should == @header
   end
   it 'should be able to get row headers with preceding empty row' do
     @oo.default_sheet = 'row_empty_row'
     @oo.records.header.should == @header
   end
   it 'should be able to get row headers with preceding empty col' do
     @oo.default_sheet = 'row_empty_col'
     @oo.records.header.should == @header
   end
   it 'should be able to get row headers with preceding empty row and column' do
     @oo.default_sheet = 'row_empty_row_col'
     @oo.records.header.should == @header
   end
end

describe 'Handle Header Exceptions' do 
  it_should_behave_like 'spreadsheet'

  it 'should throw an error on an empty sheet when parsing headers' do
    @oo.default_sheet = 'empty_sheet'
    lambda{ @oo.records.header }.should raise_error(Roo::RecordParseError)
  end
  it 'should throw an error on sheet without bold cells' do
    @oo.default_sheet = 'no_header'
    lambda{ @oo.records.header }.should raise_error(Roo::RecordParseError)
  end
  it 'should throw an error on sheet without valid header cells' do
    @oo.default_sheet = 'invalid_header'
    lambda{ @oo.records.header }.should raise_error(Roo::RecordParseError)
  end
end

describe 'Get record values' do
  it_should_behave_like 'spreadsheet'
  
  it 'should be able to parse a col record' do
    @oo.default_sheet = 'col_flush'
    @oo.records[2].to_a.should == [1.0, 2.0]
  end
  it 'should be able to parse a row record' do
    @oo.default_sheet = 'row_flush'
    @oo.records[2].to_a.should == [1.0, 2.0]
  end
end

describe 'Header index' do
  it_should_behave_like 'spreadsheet'
  
  it 'should be accessibl' do
    @oo.default_sheet = 'col_flush'
    @oo.records.header_index.should == 1
  end
end

describe 'Small datasets' do
  it_should_behave_like 'spreadsheet'
  
  it 'should be able to parse a sheet with a single col record' do
    @oo.default_sheet = 'single_cell_col'
    @oo.records.header.should == ['number']
    @oo.records[2].to_a.should == [1]
  end
  it 'should be able to parse a sheet with a single row record' do
    @oo.default_sheet = 'single_cell_row'
    @oo.records.header.should == ['number']
    @oo.records[2].to_a.should == [1]
  end
  it 'should raise an exception if the row/col does not exist' do
    @oo.default_sheet = 'single_cell_row'
    lambda{ @oo.records[3] }.should raise_error(Roo::RecordParseError)
  end
end


describe 'Dump records' do
  it_should_behave_like 'spreadsheet'

  it 'should be able to get all of the records for a col record' do
    @oo.default_sheet = 'col_flush'
    @oo.records.to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
  it 'should be able to get all of the records for a row record' do
    @oo.default_sheet = 'row_flush'
    @oo.records.to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
end

describe 'Iterate over records' do
  it_should_behave_like 'spreadsheet'

  it 'should be able to get all of the records for a col record' do
    @oo.default_sheet = 'col_flush'
    @oo.records.to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
  it 'should be able to get all of the records for a row record' do
    @oo.default_sheet = 'row_flush'
    @oo.records.to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end
end

describe 'Spreadsheet comments' do
  it 'should ignore comments'
  
end

describe 'Records should accept argument for sheet name' do
  it_should_behave_like 'spreadsheet'
  
  it 'should be able to get records for an existing sheet' do 
    @oo.records('col_flush').to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end

  it 'should be able to get records from multiple sheets' do 
    @oo.records('row_flush').to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
    @oo.records('single_cell_row').to_a.should == [[1.0]]
  end
  
  it 'should allow access to single column or row' 
  # not sure how to do this but would be nice to get a column off of a spreadsheet
  # or the nth data row, maybe the zeroth row is always the header
  # think a little more on it
end

describe 'Postprocess data types' do
  it_should_behave_like 'spreadsheet'

  add_postprocess_methods = Proc.new {
    class String
      # change all email addresses to a plussed address
      def postprocess
        if self =~ /(^[-+.\w]{1,64})@[-.\w]{1,64}\.[-.\w]{2,6}$/
          "email_prefix+#{$1}@foo.com"
        else
          self  
        end
      end
    end  
    class Float
      # convert floats to ints
      def postprocess
        self.to_i
      end
    end
  }
  remove_postprocess_methods = Proc.new {
    class String; def postprocess; self; end; end
    class Float; def postprocess; self; end; end
  }

  
  before :all do
    add_postprocess_methods.call
  end
  
  it 'should convert email addresses but not other strings' do 
    @oo.records('datatypes')[2]['some_values'].value.should == 'email_prefix+somebody@foo.com'
  end
  
  it 'should not affect other strings' do 
    @oo.records('datatypes')[4]['some_values'].value.should == 'This is a string'
  end

  it 'should convert floats to ints' do 
    @oo.records('datatypes')[3]['some_values'].value.should == 1
  end
  
  after :all do
    remove_postprocess_methods.call
  end
end

describe 'Cells that are italicized should be ignored as comments' do
  it_should_behave_like 'spreadsheet'
  
  it 'should ignore cells with an italic font' do
    @oo.records('fonts')[2]['bold'].value.should == 'first'
    @oo.records('fonts')[3]['bold'].value.should be_nil
    @oo.records('fonts')[4]['bold'].value.should == 'second'
  end
end