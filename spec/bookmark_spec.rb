specdir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.expand_path(specdir)

require 'spec/spec_helper'
require 'lib/rasta/spreadsheet'
require 'roo'

testfile = File.join(specdir, 'spreadsheets/spreadsheet_parsing.xls')

describe 'Bookmarks without commandline options' do
  before :all do
    @bookmark = Rasta::Spreadsheet::Bookmark.new
  end
  it 'should start with the proper defaults' do
    @bookmark.page_count.should == 0
    @bookmark.max_page_count.should == 0
    @bookmark.record_count.should == 0
    @bookmark.max_record_count.should == 0
    @bookmark.continue.should == false
  end
  it 'should always find the page' do
    @bookmark.found_page?('foo').should == true
  end
  it 'should always find the record' do
    @bookmark.found_record?('foo').should == true
  end
  it 'should never exceed max records' do
    @bookmark.exceeded_max_records?.should == false
  end
end

describe 'Bookmark with commandline options' do
  it 'should be able to find a bookmarked page' do
    @bookmark = Rasta::Spreadsheet::Bookmark.new(:continue => 'MyPage')
    @bookmark.found_page?('foo').should == false
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(3).should == true
    @bookmark.exceeded_max_records?.should == false
  end
  it 'should be able to find a bookmarked page with record' do
    @bookmark = Rasta::Spreadsheet::Bookmark.new(:continue => 'MyPage[D]')
    @bookmark.found_page?('foo').should == false
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(3).should == false
    @bookmark.found_record?(4).should == true
    @bookmark.exceeded_max_records?.should == false
  end
  it 'should be able to continue given number of pages' do
    @bookmark = Rasta::Spreadsheet::Bookmark.new(:pages => 1)
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(4).should == true
    @bookmark.exceeded_max_records?.should == false # pages = 0
    @bookmark.page_count += 1
    @bookmark.exceeded_max_records?.should == false # pages = 1
    @bookmark.page_count += 1
    @bookmark.exceeded_max_records?.should == true  # pages = 2
  end
  it 'should be able to continue a given number of records' do
    @bookmark = Rasta::Spreadsheet::Bookmark.new(:records => 1)
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(4).should == true
    @bookmark.exceeded_max_records?.should == false # records = 0
    @bookmark.record_count += 1
    @bookmark.exceeded_max_records?.should == false # records = 1
    @bookmark.record_count += 1
    @bookmark.exceeded_max_records?.should == true  # records = 2
  end
end
 
describe 'Bookmark parsing' do
  before :all do
    @bookmark = Rasta::Spreadsheet::Bookmark.new
  end
  it 'should parse an empty bookmark' do
    @bookmark.parse_bookmark(nil).should == [nil,nil]
  end
  it 'should parse a page without a record' do
    @bookmark.parse_bookmark('MyPage').should == ['MyPage',nil]
  end
  it 'should parse a page with a numeric record' do
    @bookmark.parse_bookmark('MyPage[1]').should == ['MyPage',1]
  end
  it 'should parse a page with an alpha record' do
    @bookmark.parse_bookmark('MyPage[A]').should == ['MyPage',1]
  end
  it 'should parse a page with an extended alpha record' do
    @bookmark.parse_bookmark('MyPage[AA]').should == ['MyPage',27]
  end
  it 'should handle lowercase records' do
    @bookmark.parse_bookmark('MyPage[aa]').should == ['MyPage',27]
  end
  it 'should parse a page with an embedded comment' do
    @bookmark.parse_bookmark('MyPage#comment').should == ['MyPage#comment',nil]
  end
  it 'should raise an exception for an invalid bookmark' do
    lambda{ @bookmark.parse_bookmark("[1]") }.should raise_error(Rasta::Spreadsheet::BookmarkError)
  end
  it 'should raise an exception for an invalid bookmark record' do
    lambda{ @bookmark.parse_bookmark("MyPage[foo1]") }.should raise_error(Rasta::Spreadsheet::BookmarkError)
  end
end

describe 'Bookmark parsing on worksheet' do
  it 'should handle bookmarks to invalid worksheets'
  it 'should handle bookmarks to invalid records'
end