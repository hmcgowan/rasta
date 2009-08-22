require File.join(File.dirname(__FILE__), 'spec_helper')

require 'roo'
require 'rasta/fixture/classic_fixture'

class PageFixture
  include Rasta::Fixture::RastaClassicFixture
end  

describe 'classic fixture' do
  class ClassicFixture
    include Rasta::Fixture::RastaClassicFixture
  end  
  it 'should initialize properly' do
    roo = Roo::Spreadsheet.open(File.join(Test::Spreadsheet_dir, 'rasta_fixture.xls'))
    fixture = ClassicFixture.new
    lambda{fixture.initialize_fixture(roo, nil)}.should_not raise_error
  end
end

describe 'page fixture' do
  class PageFixture
    include Rasta::Fixture::RastaClassicFixture
  end  
  it 'should initialize properly' do
    roo = Roo::Spreadsheet.open(File.join(Test::Spreadsheet_dir, 'rasta_fixture.xls'))
    fixture = PageFixture.new
    lambda{fixture.initialize_fixture(roo, nil)}.should_not raise_error
  end
end
