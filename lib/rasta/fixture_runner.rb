require 'rubygems'
require 'spec'
require 'fileutils'
require 'logrotate'
require 'roo'
require 'rasta/extensions/rspec_extensions'
require 'rasta/extensions/roo_extensions'
require 'rasta/fixture/metrics'

module Rasta
  class ClassLoader
    attr_reader :required_files
    
    def initialize(path)
      @@class_constants = {}
      @fixture_path = path
      @required_files = []      
    end
    
    # Load the files in the fixture path and 
    # track which classes got loaded
    def load_test_fixtures
      if File.directory?(@fixture_path)
        fixture_files = File.join(@fixture_path, "**", "*.rb")
      elsif File.exists?(File.expand_path(@fixture_path))
        fixture_files = File.expand_path(@fixture_path)
      else
        raise IOError, "Unable to locate test fixtures using #{@fixture_path}" 
      end
      Dir.glob(fixture_files).each {|f| require f; @required_files << f}
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
      prepare_results_directory
      start_rspec
      run_test_fixtures
      stop_rspec
    end

    def prepare_results_directory
      if File.directory?(@options[:results_path])
        rotate_result_files
      else
        FileUtils.mkdir_p(@options[:results_path]) 
      end  
    end
    
    def rotate_result_files
      rotate_dir = File.join(@options[:results_path], 'previous_runs')
      FileUtils.mkdir_p(rotate_dir) unless File.directory?(rotate_dir)
      options = {:count=>10, :directory=>rotate_dir}
      xml_file = File.join(@options[:results_path], 'spreadsheet.xml')
      html_file = File.join(@options[:results_path], 'spreadsheet.html')
      LogRotate.rotate_file(xml_file, options) if File.exists?(xml_file)
      LogRotate.rotate_file(html_file, options) if File.exists?(html_file)
    end
    
    #TODO: work out way to specify which formatters you want to include
    def start_rspec
      require 'spec/runner/formatter/progress_bar_formatter' 
      require 'rasta/formatter/spreadsheet_formatter'
      Spec::Runner.options.backtrace_tweaker = Spec::Runner::NoisyBacktraceTweaker.new
      @options[:formatters] ||= {
        'ProgressBarFormatter' => nil,
        'BaseTextFormatter' => 'results.txt',
        'SpreadsheetFormatter' => 'spreadsheet.xml'
      }
      # TODO: Spec::Runner.options.parse_format("Formatter::")  if @options[:formatters].has_key?('CIREPORTER') 
      @options[:formatters].each_key do |key|
        if @options[:formatters][key]
          path = ':' + File.join(@options[:results_path], @options[:formatters][key])
        else
          path = ''
        end
        Spec::Runner.options.parse_format("Formatter::#{key}#{path}")
        Spec::Runner.options.reporter.initialize_spreadsheet if key == 'SpreadsheetFormatter'
      end
    end
    private :start_rspec
   
    def run_test_fixtures
      @options[:spreadsheets].each do |spreadsheet| 
        roo = Roo::Spreadsheet.open(spreadsheet)
        Spec::Runner.options.reporter.roo = roo 

        @loader = ClassLoader.new(@options[:fixture_path])
        @loader.load_test_fixtures
        bookmark = Rasta::Bookmark.new(@options)
        roo.sheets.each do |sheet| 
          next if sheet =~ /^#/ #skip sheets that are only comments
          begin
            roo.default_sheet = sheet
            base_sheet_name = roo.default_sheet.gsub(/#.*/, '') 
            classname = @loader.find_class_by_name(base_sheet_name)
            fixture = classname.new
            if @options[:extend_fixture]
              fixture.extend( @options[:extend_fixture])
            end
            fixture.initialize_fixture(roo, bookmark)
          rescue ArgumentError => e
            raise ArgumentError, "Unable to load class #{@classname}. Make sure the class includes the Rasta fixture: #{e.inspect + e.backtrace.join("\n")}"
          end
          fixture.execute_worksheet
        end
      end  
    end
    private :run_test_fixtures

    def stop_rspec
      Spec::Runner.options.reporter.original_dump if Spec::Runner.options
      Spec::Runner.options.clear_format_options
    end
    private :stop_rspec
  end
  
end 