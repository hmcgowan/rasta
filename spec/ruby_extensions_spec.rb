lib_dir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.expand_path(lib_dir)

require 'spec/spec_helper'
require 'rasta/extensions/ruby_extensions'


describe 'Dataype Conversions' do
  it 'should be able to convert boolean values' do
    'true'.to_datatype.should == true
    'false'.to_datatype.should == false
    'TRUE'.to_datatype.should == true
    'FALSE'.to_datatype.should == false
  end
  it 'should be able to convert arrays' do 
    "[1,2,3]".to_datatype.should == [1,2,3]
    "['a','b','c']".to_datatype.should == ['a','b','c']
    "[{:a=>1},{:b=>2}]".to_datatype.should == [{:a=>1},{:b=>2}]
    "[['a','b','c'],['d','e','f']]".to_datatype.should == [['a','b','c'],['d','e','f']]
  end
  it 'should be able to convert hashes' do 
    "{:a=>1}".to_datatype.should == {:a => 1}
    "{:a=>'1'}".to_datatype.should == {:a => '1'}
    "{:a=>[1], :b=>[2,3]}".to_datatype.should == {:a=>[1], :b=>[2,3]}
    "{:a => {:a=>'1'},:b => {:b=>2}}".to_datatype.should == {:a => {:a=>'1'},:b => {:b=>2}}
  end
end
