require 'rubygems'
require 'spec'
require 'fileutils'
require 'roo'
require 'rasta/extensions/roo_extensions'
require 'rasta/spreadsheet'
require 'rasta/html'


module Rasta

  class FixtureRunner
    
    def initialize(opts)
      @options = opts
    end
    
    def execute
      prepare_results_directory
      start_rspec
      run_spreadsheet
      stop_rspec
    end

    def run_spreadsheet
      roo = open_spreadsheet(@options[:spreadsheet])
      Rasta::Spreadsheet::Bookmark.read(@options)
      @loaded_classes = load_test_fixtures
# Find out the right place to put this
html = Rasta::HTML.new
      roo.sheets.each do |sheet| 
        next if sheet =~ /^#/
        next if !Rasta::Spreadsheet::Bookmark.found_page?(sheet)
        roo.default_sheet = sheet

html.add_tab(roo)
html.write(@options[:results_path] + '/' + File.basename(@options[:spreadsheet]) + '.html')
        run_test_fixture(roo)
        return if Rasta::Spreadsheet::Bookmark.exceeded_max_records?
     end

    end
    private :run_spreadsheet

    def open_spreadsheet(filename)
      case File.extname(filename)
      when '.xls'
        Excel.new(filename)
      when '.xlsx'
        Excelx.new(filename)
      when '.ods'
        Openoffice.new(filename)
      when ''
        Google.new(filename)
      else
        raise ArgumentError, "Don't know how to handle spreadsheet #{filename}"
      end        
    end
    
    def run_test_fixture(roo)
      # remove comments from tabnames
      # In order to have multiple spreadsheet tabs with the 
      # same name we're allowing the tabs to have a comment 
      # so that Class#this and Class#that can exist in the
      # same workbook and call the same test fixture
      base_sheet_name = roo.default_sheet.gsub(/#.*/, '')
      classname = find_class_by_name(base_sheet_name)
      begin
        fixture = classname.new
        fixture.initialize_test_fixture(roo)
      rescue ArgumentError => e
        raise ArgumentError, "Unable to load class #{@classname}. Make sure the class includes the Rasta fixture: #{e.inspect + e.backtrace.join("\n")}"
      end
      
      # Run the test fixture
      fixture.generate_rspec_tests
    end
    private :run_test_fixture
    
    def prepare_results_directory
      if ! File.exists?(File.expand_path(@options[:spreadsheet]))
        if File.extname(@options[:spreadsheet]) != '' # don't check google keys
          raise IOError, "File not found: #{@options[:spreadsheet]}" 
        end
      end
      
      if File.expand_path(@options[:results_path]) != @options[:results_path]
        @options[:results_path] = Dir.getwd + '/' + @options[:results_path]
      end
      
      # Remove the existing results 
      if File.exists?(@options[:results_path])
        FileUtils.rm(Dir.glob(File.join(@options[:results_path], "*")))
      else
        begin
          FileUtils.mkdir_p(@options[:results_path]) if !File.exists?(@options[:results_path])
        rescue => e
          puts "Creating directory #{@options[:results_path]}"
          raise IOError, e.message
        end
      end
    end
    private :prepare_results_directory
    
    # Load the files in the fixture path and 
    # track which classes got loaded so we can hopefully
    # reduce the chance of namespace issues. There may 
    # be a better way to handle this
    def load_test_fixtures
      before_classes = []
      after_classes = []
      ObjectSpace.each_object(Class) { |x| before_classes << x.name } 
      # Look through all of the .rb files in the fixture path to see if 
      # we can find the file that has the class specified
      if File.directory?(@options[:fixture_path])
        fixture_files = File.join(@options[:fixture_path].gsub('\\','/'), "**", "*.rb")
        Dir.glob(fixture_files).each {|f| do_require f }
      else
        do_require @options[:fixture_path]
      end  
      ObjectSpace.each_object(Class) { |x| after_classes << x.name } 
      return (after_classes - before_classes)
    end
    private :load_test_fixtures

    def do_require(filename)
      raise LoadError, "Unable to require file '#{filename}'" unless require filename
    end
    private :do_require
      
    def find_class_by_name(classname)
      ObjectSpace.each_object(Class) do |klass| 
        next unless @loaded_classes.include?(klass.name)
        return klass if klass.name =~ /(^|:)#{classname}$/
      end
      raise ArgumentError, "Class '#{@options[:moduile]}::#{classname}' not found!"
    end
    private :find_class_by_name
    
    def start_rspec
      require 'rasta/extensions/rspec_extensions'
      require 'spec/runner/formatter/progress_bar_formatter'
      require 'spec/runner/formatter/html_formatter'
      Spec::Runner.options.backtrace_tweaker = Spec::Runner::NoisyBacktraceTweaker.new
      Spec::Runner.options.parse_format("Formatter::ProgressBarFormatter")
      Spec::Runner.options.parse_format("Formatter::BaseTextFormatter:#{@options[:results_path]}/results.txt")
      Spec::Runner.options.parse_format("Formatter::HtmlFormatter:#{@options[:results_path]}/results.html")

#      require 'rasta/formatter/spreadsheet_formatter'
#      Spec::Runner.options.parse_format("Formatter::SpreadsheetFormatter:#{@options[:results_path]}/spreadsheet.out")
#      Spec::Runner.options.reporter.initialize_spreadsheet
    end
    private :start_rspec
    
    def stop_rspec
      Spec::Runner.options.reporter.original_dump if Spec::Runner.options
      Spec::Runner.options.clear_format_options;
    end
    private :stop_rspec
  end
  
end 