lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.expand_path(lib_dir)

require 'rubygems'
require 'rasta'
Root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
# need to udpate examples and move this into spec?
testfile = File.join(Root_dir, 'examples', 'rasta_fixture.ods')
fixture_path = File.join(Root_dir, 'examples', 'fixtures')

Rasta::SpreadsheetRunner.new.execute(:spreadsheet => testfile, :fixture_path => fixture_path, :results_path => '../rasta_test_results', :records => 1)


# look at possibility of adding way to get text results from here for testing the commandline opts