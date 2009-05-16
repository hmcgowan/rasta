TESTFILE = TOPDIR + '/spec/sandbox/spreadsheets/rasta_fixture.xls'

require TOPDIR + '/spec/sandbox/fixtures/RastaTestFixture'
require 'lib/rasta/spreadsheet'

describe 'SpreadsheetTab', :shared => true do
  before(:all) do 
    @book = Rasta::Spreadsheet::Book.new(TESTFILE)
    @sheet = nil
  end
  after(:all) do 
    Rasta::Spreadsheet::Excel.instance.cleanup 
  end

end

#describe "Test Fixture Attributes" do
#  it_should_behave_like 'SpreadsheetTab'
#  before(:all) do
#    @sheetname = @book['TestFixture#1']
#    @fixture = RastaTestFixture.new
#    @fixture.instance_eval {@sheet = @sheetname}
#    @fixture.instance_eval {@metrics = Metrics.new}
#  end
#  it "should reset attributes between records" do 
#    @fixture.call_fixture_attribute('a','test')
#    @fixture.clear_attributes
#    @fixture.a.should be_nil
#  end
#end

#describe "Test Fixture Methods" do
#end