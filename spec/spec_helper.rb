Lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
Spec_dir = File.join(File.dirname(__FILE__))
Sandbox_dir = File.join(Spec_dir, 'sandbox')
Fixture_dir = File.join(Sandbox_dir, 'fixtures')
Spreadsheet_dir = File.join(Sandbox_dir, 'spreadsheets')

$LOAD_PATH.unshift File.expand_path(Lib_dir)

require 'rubygems'
require 'spec'