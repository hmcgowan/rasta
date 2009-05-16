TOPDIR = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.expand_path(TOPDIR)

require 'spec/spec_helper'

require 'lib/rasta'

require TOPDIR + '/lib/rasta/fixture/base_fixture'
describe "Metrics" do
  it "should increment :attribute_count" do
    m = Rasta::Fixture::BaseFixture::Metrics.new
    m.inc(:attribute_count)
    m.attribute_count.should == 1
  end
  it "should increment :method_count" do
    m = Rasta::Fixture::BaseFixture::Metrics.new
    m.inc(:method_count)
    m.method_count.should == 1
  end
  it "should increment :attribute_count" do
    m = Rasta::Fixture::BaseFixture::Metrics.new
    m.inc(:record_count)
    m.record_count.should == 1
  end
end
