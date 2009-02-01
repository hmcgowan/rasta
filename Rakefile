$:.unshift('lib')
 
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

RCOV_DIR = 'rcov'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name               = 'rasta'
    s.rubyforge_project  = 'rasta'
    s.platform           = Gem::Platform::CURRENT
    s.email              = 'hugh_mcgowan@yahoo.com' 
    s.homepage           = "http://github.com/hmcgowan/rasta"
    s.summary            = "Rasta"
    s.description        = <<-EOF
        Rasta is a keyword-driven test framework based on Roo, using spreadsheets
        to drive test automation. It is loosely based on FIT - tables
        define test parameters which call your test fixture. As the
        test runs, the spreadsheet is updated with test results.
    EOF
    s.authors            = ['Hugh McGowan']

    s.executables        = ['rasta']
    s.files              =  FileList[ "{bin,lib,spec}/**/*"]
    s.add_dependency "rspec", [">= 1.1.11"]
    s.add_dependency "roo", [">= 1.1.11"]
    s.add_dependency "user-choices", [">= 1.1.6"]

    s.has_rdoc = true
    s.extra_rdoc_files = ["README", "LICENSE"]
    s.rdoc_options = ["--main","README"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
 
Spec::Rake::SpecTask.new('test') do |t|
  t.libs << File.join(File.dirname(__FILE__), 'lib')
  t.spec_files = FileList['spec/**/*_.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.libs << File.join(File.dirname(__FILE__), 'lib')
  t.rcov = true
  t.rcov_dir = RCOV_DIR
  t.rcov_opts << '--text-report'
  t.rcov_opts << '--exclude spec'
end

task :default => :test

