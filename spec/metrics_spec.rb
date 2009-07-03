require File.join(File.dirname(__FILE__), 'spec_helper')

require 'rasta/fixture/metrics'

describe 'Metrics' do
  before :all do
    @metrics = Rasta::Fixture::Metrics.new
  end
  
  it 'should be able to reset page counts' do
    @metrics.record_count += 1
    @metrics.method_count += 1
    @metrics.attribute_count += 1
    @metrics.reset_page_counts
    @metrics.record_count.should == 0
    @metrics.method_count.should == 1
    @metrics.attribute_count.should == 1
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
