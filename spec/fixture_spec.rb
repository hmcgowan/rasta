require File.join(File.dirname(__FILE__), 'spec_helper')

require 'roo'
require 'rasta/fixture/action_fixture'


describe 'classic fixture' do
  require 'rasta/fixture/classic_fixture'
  class ClassicFixture
    include Rasta::Fixture::ClassicFixture
  end  
  it 'should initialize properly' do
    roo = Roo::Spreadsheet.open(File.join(Test::Spreadsheet_dir, 'rasta_fixture.xls'))
    fixture = ClassicFixture.new
    lambda{fixture.initialize_fixture(roo, nil)}.should_not raise_error
  end
end

describe 'page fixture' do
  require 'rasta/fixture/page_fixture'
  class ClassicFixture
    include Rasta::Fixture::ClassicFixture
  end  
  it 'should initialize properly' do
    roo = Roo::Spreadsheet.open(File.join(Test::Spreadsheet_dir, 'rasta_fixture.xls'))
    fixture = ClassicFixture.new
    lambda{fixture.initialize_fixture(roo, nil)}.should_not raise_error
  end
end

describe 'action fixture' do
  require 'rasta/fixture/action_fixture'
  class ActionFixture
    include Rasta::Fixture::ActionFixture
  end
  it 'should initialize properly' do
     roo = Roo::Spreadsheet.open(File.join(Test::Spreadsheet_dir, 'rasta_fixture.xls'))
     fixture = ActionFixture.new
     lambda{fixture.initialize_fixture(roo, nil)}.should_not raise_error
   end
end