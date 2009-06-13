require 'rubygems'
require 'spec'
require 'fileutils'
require 'roo'
require 'rasta/extensions/rspec_extensions'
require 'rasta/extensions/roo_extensions'
require 'rasta/fixture/metrics'

module Rasta
  
  class ClassLoader
    
    def initialize(path)
      @fixture_path = path
      @@class_constants = {}
    end
    
    # Load the files in the fixture path and 
    # track which classes got loaded
    def load_test_fixtures
      fixture_files = File.join(@fixture_path, "**", "*.rb")
      Dir.glob(fixture_files).each {|f| require f }
    end

    # Get the reference to a class based on a string. Also 
    # check to see if it's a class that we loaded
    def find_class_by_name(classname)
      return @@class_constants[classname] if @@class_constants[classname]
      ObjectSpace.each_object(Class) do |klass| 
        if klass.name =~ /(^|:)#{classname}$/
          @@class_constants[classname] = klass
          return klass
        end
      end
      raise LoadError, "Class '#{classname}' not found!"
    end

  end

  class FixtureRunner
        
    def initialize(opts)
      @options = opts
    end
    
    def execute
      create_results_directory(@options[:results_path])
      start_rspec
      run_test_fixtures
      stop_rspec
    end

    def create_results_directory(results_dir)
      FileUtils.rm_r(results_dir) if File.directory?(results_dir) 
      FileUtils.mkdir_p(results_dir) 
    end
    
    def start_rspec
      require 'spec/runner/formatter/progress_bar_formatter' 
      require 'rasta/formatter/spreadsheet_formatter'
      Spec::Runner.options.backtrace_tweaker = Spec::Runner::NoisyBacktraceTweaker.new
      Spec::Runner.options.parse_format("Formatter::ProgressBarFormatter")  
      Spec::Runner.options.parse_format("Formatter::BaseTextFormatter:#{@options[:results_path]}/results.txt")
      Spec::Runner.options.parse_format("Formatter::SpreadsheetFormatter:#{@options[:results_path]}/spreadsheet.xml")
      Spec::Runner.options.reporter.initialize_spreadsheet
    end
    private :start_rspec
   
    def run_test_fixtures
      @options[:spreadsheets].each do |spreadsheet| 
        roo = Roo::Spreadsheet.open(spreadsheet)
        Spec::Runner.options.reporter.roo = roo 

        @loader = ClassLoader.new(@options[:fixture_path])
        @loader.load_test_fixtures
        roo.sheets.each do |sheet| 
          next if sheet =~ /^#/ #skip sheets that are only comments
          begin
            roo.default_sheet = sheet
            base_sheet_name = roo.default_sheet.gsub(/#.*/, '') 
            classname = @loader.find_class_by_name(base_sheet_name)
            fixture = classname.new
            fixture.initialize_test_fixture(roo)
          rescue ArgumentError => e
            raise ArgumentError, "Unable to load class #{@classname}. Make sure the class includes the Rasta fixture: #{e.inspect + e.backtrace.join("\n")}"
          end
          fixture.generate_rspec_tests
        end
      end  
    end
    private :run_test_fixtures

    def stop_rspec
      Spec::Runner.options.reporter.original_dump if Spec::Runner.options
      Spec::Runner.options.clear_format_options;
    end
    private :stop_rspec
  end
  
end 