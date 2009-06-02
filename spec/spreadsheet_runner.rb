Spec_dir = File.join(File.dirname(__FILE__))
require File.join(Spec_dir, 'spec_helper')

require 'rasta'

# need to udpate examples and move this into spec?
testfile = File.join(Root_dir, 'examples', 'rasta_fixture.xls')
fixture_path = File.join(Root_dir, 'examples', 'fixtures')

Rasta::SpreadsheetRunner.new.execute(:spreadsheet => testfile, :fixture_path => fixture_path, :results_path => '../rasta_test_results') 
