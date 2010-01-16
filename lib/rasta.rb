module Rasta
  require 'user-choices'
  require 'rasta/fixture_runner'
  
  class SpreadsheetRunner < UserChoices::Command
    include UserChoices
    def add_sources(builder)
      builder.add_source(CommandLineSource, :usage, "Usage ruby #{$0} [options] filename")
    end
    
    def add_choices(builder)
      builder.add_choice(:results_path, :type=>:string, :default=>'rasta_test_results') do | command_line |
        command_line.uses_option("-r", "--results-path PATH", "Location of test results.")
      end
      builder.add_choice(:bookmark, :type=>:string, :default=>nil) do | command_line |
        command_line.uses_option("-c", "--continue BOOKMARK", "Continue spreadsheet from a given bookmark.")
      end
      builder.add_choice(:pages, :type=>:integer, :default=>0) do | command_line |
        command_line.uses_option("--pages [COUNT]", "Number of pages to process.")
      end
      builder.add_choice(:records, :type=>:integer, :default=>0) do | command_line |
        command_line.uses_option("--records [COUNT]", "Number of records to process.")
      end
      builder.add_choice(:version, :type=>:boolean, :default=>false) do | command_line |
        command_line.uses_option("-v", "--version", "Location of test fixtures.")
      end
      builder.add_choice(:help, :type=>:boolean, :default=>false) do | command_line |
        command_line.uses_option("-h", "--help", "Show detailed usage.")
      end
      builder.add_choice(:spreadsheets) { | command_line |
        command_line.uses_arglist
      }
    end
    
    def execute(choices = {})
      postprocess_choices(choices)
      clear_commandline_arguments
      start_interrupt_handler        
      run_tests
      exit_gracefully if @user_choices[:runtime_environment] == :shell
    end

    # We're not using the built-in postprocess_user_choices because
    # we want to process after we've merged in any choices diectly specified
    # if we call this through ruby code and not a commandline
    def postprocess_choices(choices)
      if choices == {}
        @user_choices[:runtime_environment] = :shell
      else
        @user_choices[:runtime_environment] = :script
        @user_choices.merge!(choices)
      end  
      if @user_choices[:help]
        puts @user_choices[:usage]
        exit 0
      elsif @user_choices[:version]
        require 'rasta/version'
        puts Rasta::VERSION::DESCRIPTION
        exit 0
      end
      @user_choices[:spreadsheets] << @user_choices[:spreadsheet] if @user_choices[:spreadsheet] 
      @user_choices[:results_path] = File.expand_path(@user_choices[:results_path]) if @user_choices[:results_path] 
    end
    
    # If we don't clear out ARGV, then RSPEC 
    # will try to use arguments as RSPEC inputs
    def clear_commandline_arguments
      ARGV.shift while ARGV.length > 0 
    end
    private :clear_commandline_arguments

    def start_interrupt_handler
      trap "SIGINT", proc { puts "User Interrupt!!!\nExiting..." ; exit 1}
    end
    private :start_interrupt_handler

    def run_tests
      fixture_runner = Rasta::FixtureRunner.new(@user_choices)
      fixture_runner.execute
    end
    private :run_tests
    
    def exit_gracefully 
      puts
      puts "Test results are available in #{@user_choices[:results_path]}"
      exit 0
    end
    private :exit_gracefully
  end
   
 end