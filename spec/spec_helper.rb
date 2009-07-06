lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.expand_path(lib_dir)

require 'rubygems'
require 'spec'
require 'rasta/extensions/rspec_extensions'

# Because Rasta modifies the default behaviour of RSpec 
# we need to restore that functionality so we can 
# use it for the unit tests. 
#
# TODO: look to see if it would be better to conditionally
# require the rspec_extensions...
module Spec
  module Runner
    class Reporter
      alias :dump :original_dump
      alias :start :original_start
      alias :example_finished :old_example_finished 
    end
    class Options
      def clear_format_options; end
    end    
  end
  module Matchers
    class RaiseError 
      alias :matches? :old_matches? 
    end
  end    
end

module Test
  Root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  Sandbox_dir = File.expand_path(File.join(File.dirname(__FILE__), 'sandbox'))
  Fixture_dir = File.join(Sandbox_dir, 'fixtures')
  Spreadsheet_dir = File.join(Sandbox_dir, 'spreadsheets')
end


