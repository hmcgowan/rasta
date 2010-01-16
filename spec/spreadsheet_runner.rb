lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.expand_path(lib_dir)

require 'rubygems'
require 'rasta'
Root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

fixture_path = File.join(Root_dir, 'examples', 'fixtures')

testfile = File.join(Root_dir, 'examples', 'rasta_fixture.ods')


# require the test fixtures
Dir.glob(File.join(fixture_path, "**", "*.rb")).each {|f| require f} 

Rasta::SpreadsheetRunner.new.execute(:spreadsheet => testfile, :results_path => '../rasta_test_results')
