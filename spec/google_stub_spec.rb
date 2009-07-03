require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Roo Extensions' do
  before :all do
    class GenericSpreadsheet; end
    require 'rasta/extensions/roo_extensions'
    class Google; def initialize; end; end # stub out Google's init so we don't have to pass in a valid ID
    @oo = Google.new
  end
  it 'should implement a font interface for Google docs' do
    @oo.font(2,1).class.should == Google::Font
  end
  it 'should see the first column as bold (forces column fixture)' do
    @oo.font(2,1).bold?.should == true
  end
  it 'should see the any other column as normal' do
    @oo.font(2,2).bold?.should == false
  end
end