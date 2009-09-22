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

describe Roo::RecordCell do
  it_should_behave_like 'spreadsheet'

  before :all do
    @oo.default_sheet = 'record_cell'
  end
  
  def check(row,col,raw,val,klass)
    cell = Roo::RecordCell.new(@oo, row, col)
    cell.value.should == val
    cell.raw_value.should == raw
    cell.value.class.should == klass
  end
  
  it 'should be to initialize a new cell properly' do
    @oo.records[0][0].class.should == Roo::RecordCell
  end

  it 'should read the cell value for a string' do
    check 2, 1, 'a', 'a', String
  end

  it 'should read the cell value for an integer' do
    check 3, 1, 1.0, 1.0, Float
  end

  it 'should set italic cell values to nil' do
    check 4, 1, 'test', nil, NilClass
  end    
  
  it 'should see italic cells as empty' do
    cell = Roo::RecordCell.new(@oo, 4, 1)
    cell.empty?.should be_true
  end
end

describe Roo::Record do
  it_should_behave_like 'spreadsheet'
  
  before :all do
    @row_oo = @oo.dup
    @row_oo.default_sheet = 'row_flush'
    @row_record = Roo::Record.new(:row, 2, @row_oo, Roo::RecordHeader.new(@row_oo))
    @col_oo = @oo.dup
    @col_oo.default_sheet = 'col_flush'
    @col_record = Roo::Record.new(:column, 2, @col_oo, Roo::RecordHeader.new(@col_oo))
  end
  
  it 'should be able to read a row record' do
    @row_record.to_a.should == [1.0, 2.0]
    @row_record[0].value.should == 1.0
    @row_record[1].value.should == 2.0
    @row_record.name.should == 'B'
  end
  
  it 'should be able to read a column record' do
    @col_record.to_a.should == [1.0, 2.0]
    @col_record[0].value.should == 1.0
    @col_record[1].value.should == 2.0
    @col_record.name.should == '2'
  end
  
  it 'should be able to iterate over records' do
    cells = []
    @col_record.each {|x| cells << x.value}
    cells.should == [1.0,2.0]
  end  
  
  it 'should throw an exceptions when an out of range request is made' do
    lambda{@row_record['GG']}.should raise_error(RangeError)
    lambda{@col_record[2]}.should raise_error(RangeError)
    lambda{@col_record[//]}.should raise_error(RangeError)
  end
  
  it 'should not recognize a row with values as empty' do
    @oo.default_sheet = 'empty_records'
    record = Roo::Record.new(:column, 2, @oo, Roo::RecordHeader.new(@oo))
    record.empty?.should be_false
  end

  it 'should recognize a row with only italicized values as empty' do
    @oo.default_sheet = 'empty_records'
    record = Roo::Record.new(:column, 3, @oo, Roo::RecordHeader.new(@oo))
    record.empty?.should be_true
  end

  it 'should recognize a null row as empty' do
    @oo.default_sheet = 'empty_records'
    record = Roo::Record.new(:column, 4, @oo, Roo::RecordHeader.new(@oo))
    record.empty?.should be_true
  end
  
  it 'should be able to parse a sheet with a single column record' do
     @oo.default_sheet = 'single_cell_col'
     record = Roo::Record.new(:column, 2, @oo, Roo::RecordHeader.new(@oo))
     record.to_a.should == [1]
  end

  it 'should be able to parse a sheet with a single column record' do
     @oo.default_sheet = 'single_cell_row'
     record = Roo::Record.new(:row, 2, @oo, Roo::RecordHeader.new(@oo))
     record.to_a.should == [1]
  end
  
end

describe Roo::Records do

  it_should_behave_like 'spreadsheet'

  it 'header index should be accessible' do
    @oo.records('col_flush').header_index.should == 1
  end
  
  it 'should be able to get records from multiple sheets' do 
    @oo.records('row_flush').to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
    @oo.records('single_cell_row').to_a.should == [[1.0]]
  end


  it 'should be able to get all of the records for a col record' do
    @oo.records('col_flush').to_a.should== [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end

  it 'should be able to get all of the records for a row record' do
    @oo.records('row_flush').to_a.should == [[1.0, 2.0], [2.0, 1.0], [3.0, 0.0], [4.0, 2.0], [5.0, 0.0], [3.0, 4.0]]
  end

  it 'should ignore text outside the defined table' do
    @oo.records('empty_records').to_a.should == [['a','b']]
  end 

  it 'should raise an exception if the row/col does not exist' do
    @oo.default_sheet = 'single_cell_row'
    lambda{ @oo.records[3] }.should raise_error(RangeError)
  end
 
  
  
end

describe Roo::RecordHeader do 
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
  
  it 'should identify the first header' do
    @oo.default_sheet = 'col_flush'
    @record_header = Roo::RecordHeader.new(@oo)
    @record_header.first_record.should == 2
  end    
  it 'should identify the last last' do
    @oo.default_sheet = 'col_flush'
    @record_header = Roo::RecordHeader.new(@oo)
    @record_header.last_record.should == 7
  end    

  it 'should stop parsing the header on a nil header value' do
    @oo.default_sheet = 'empty_records'
    @record_header = Roo::RecordHeader.new(@oo)
    @record_header.values.should == ['ColA','ColB']
  end    
  
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
    @oo.records('datatypes')[0]['some_values'].value.should == 'email_prefix+somebody@foo.com'
  end
  
  it 'should not affect other strings' do 
    @oo.records('datatypes')[2]['some_values'].value.should == 'This is a string'
  end

  it 'should convert floats to ints' do 
    @oo.records('datatypes')[1]['some_values'].value.should == 1
  end
  
  after :all do
    remove_postprocess_methods.call
  end
end

