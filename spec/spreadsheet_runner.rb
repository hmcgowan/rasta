lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.expand_path(lib_dir)

require 'rubygems'
require 'rasta'
Root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

fixture_path = File.join(Root_dir, 'examples', 'fixtures')

testfile = File.join(Root_dir, 'examples', 'rasta_fixture.ods')

Rasta::SpreadsheetRunner.new.execute(:spreadsheet => testfile, :fixture_path => fixture_path, :results_path => '../rasta_test_results')


# need to figure out how to handle before and after wrt reporting because the cells won't exist in the xml output. 