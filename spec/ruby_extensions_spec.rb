lib_dir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.expand_path(lib_dir)

require 'spec/spec_helper'
require 'rasta/extensions/ruby_extensions'


describe 'Dataype Conversions' do
  it 'should be able to handle boolean values' do
    'true'.to_datatype!.should == true
    'false'.to_datatype!.should == false
    
  end

  it 'should be able to reset record counts' do
    @metrics.record_count += 1
    @metrics.method_count += 1
    @metrics.attribute_count += 1
    @metrics.reset_record_counts
    @metrics.record_count.should == 1
    @metrics.method_count.should == 0
    @metrics.attribute_count.should == 0
  end

end
