require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rasta/extensions/ruby_extensions'

describe 'Convert strings to dataypes' do
   
   it 'should trim whitespace' do 
     '    This is a string   '.to_datatype.should == 'This is a string'
   end
   it 'should convert strings to strings' do 
     'This is a string'.to_datatype.should == 'This is a string'
     'This is a string]'.to_datatype.should == 'This is a string]'
     '{This is a string'.to_datatype.should == '{This is a string'
     '/This is a string'.to_datatype.should == '/This is a string'
   end 
   it 'should handle multiline strings' do
      "This is a \nstring".to_datatype.should == "This is a \nstring"
      "This is a \rstring".to_datatype.should == "This is a \rstring"
      "This is a \r\nstring".to_datatype.should == "This is a \r\nstring"
   end
   it 'should convert arrays' do
     "['A','B','C']".to_datatype.should == ['A','B','C']
     "['A','B',['c','d']]".to_datatype.should == ['A','B',['c','d']]
   end
   it 'should convert hashes' do
     "{:a => 1, :b => 2}".to_datatype.should == {:a => 1, :b => 2}
     "{:a => 1, :b => 2, :c => {:d => 3}}".to_datatype.should == {:a => 1, :b => 2, :c => {:d => 3}}
   end
   it 'should convert numbers' do
     '0'.to_datatype.should == 0
     '1'.to_datatype.should == 1
     '1.0'.to_datatype.should == 1
     '0.0'.to_datatype.should == 0
     '0.1'.to_datatype.should == 0.1
     '1.1'.to_datatype.should == 1.1
   end
   it 'should convert boolean' do
     'TRUE'.to_datatype.should be_true
     'true'.to_datatype.should be_true
     'FALSE'.to_datatype.should be_false
     'false'.to_datatype.should be_false
   end
   it 'should not convert numbers when integer preceeded by 0' do
     '01234'.to_datatype.should == '01234'
   end
   it 'should convert regex' do
     '/test/'.to_datatype.class.should == Regexp
     '/test/mx'.to_datatype.class.should == Regexp
     "/test\n/mx".to_datatype.class.should == Regexp
   end
end