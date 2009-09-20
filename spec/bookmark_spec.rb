require File.join(File.dirname(__FILE__), 'spec_helper')

testfile = File.join(Test::Spreadsheet_dir, 'spreadsheet_parsing.xls')

require 'roo'
require 'rasta/extensions/roo_extensions'
require 'rasta/fixture/classic_fixture'

describe 'Bookmarks without commandline options' do
  before :all do
    @bookmark = Rasta::Bookmark.new
  end
  it 'should start with the proper defaults' do
    @bookmark.page_count.should == 0
    @bookmark.max_page_count.should == 0
    @bookmark.record_count.should == 0
    @bookmark.max_record_count.should == 0
    @bookmark.bookmark.should be_nil
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
    @bookmark = Rasta::Bookmark.new({:bookmark => 'MyPage'})
    @bookmark.found_page?('foo').should == false
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(3).should == true
    @bookmark.exceeded_max_records?.should == false
  end
  it 'should be able to find a bookmarked page with record' do
    @bookmark = Rasta::Bookmark.new({:bookmark => 'MyPage[D]'})
    @bookmark.found_page?('foo').should == false
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(3).should == false
    @bookmark.found_record?(4).should == true
    @bookmark.exceeded_max_records?.should == false
  end
  it 'should be able to bookmark given number of pages' do
    @bookmark = Rasta::Bookmark.new({:pages => 1})
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(4).should == true
    @bookmark.exceeded_max_records?.should == false # pages = 1
    @bookmark.page_count += 1
    @bookmark.exceeded_max_records?.should == true # pages = 2
  end
  it 'should be able to bookmark a given number of records' do
    @bookmark = Rasta::Bookmark.new({:records => 1})
    @bookmark.found_page?('MyPage').should == true
    @bookmark.found_record?(4).should == true
    @bookmark.exceeded_max_records?.should == false # records = 1
    @bookmark.record_count += 1
    @bookmark.exceeded_max_records?.should == true # records = 2
  end
end
 
describe 'Bookmark parsing' do
  before :all do
    @bookmark = Rasta::Bookmark.new
  end
  it 'should parse a page without a record' do
    @bookmark.send 'bookmark=', 'MyPage'
    @bookmark.read_bookmark
    @bookmark.page.should == 'MyPage'
    @bookmark.record.should == nil
  end
  it 'should parse a page with a numeric record' do
    @bookmark.send 'bookmark=', 'MyPage[1]'
    @bookmark.read_bookmark
    @bookmark.page.should == 'MyPage'
    @bookmark.record.should == 1
  end
  it 'should parse a page with an alpha record' do
    @bookmark.send 'bookmark=', 'MyPage[A]'
    @bookmark.read_bookmark
    @bookmark.page.should == 'MyPage'
    @bookmark.record.should == 1
  end
  it 'should parse a page with an extended alpha record' do
    @bookmark.send 'bookmark=', 'MyPage[AA]'
    @bookmark.read_bookmark
    @bookmark.page.should == 'MyPage'
    @bookmark.record.should == 27
  end
  it 'should handle lowercase records' do
    @bookmark.send 'bookmark=', 'MyPage[aa]'
    @bookmark.read_bookmark
    @bookmark.page.should == 'MyPage'
    @bookmark.record.should == 27
  end
  it 'should parse a page with an embedded comment' do
    @bookmark.send 'bookmark=', 'MyPage#comment'
    @bookmark.read_bookmark
    @bookmark.page.should == 'MyPage#comment'
    @bookmark.record.should == nil
  end
  it 'should raise an exception for an invalid bookmark' do
    lambda{
      @bookmark.send 'bookmark=', '[]'
      @bookmark.read_bookmark
    }.should raise_error(Rasta::BookmarkError)
  end
  it 'should raise an exception for an invalid bookmark record' do
    lambda{
      @bookmark.send 'bookmark=', 'MyPage[foo1]'
      @bookmark.read_bookmark
    }.should raise_error(Rasta::BookmarkError)
  end
end
