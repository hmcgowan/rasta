$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
 
require 'rubygems'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'spec/rake/verify_rcov'

PKG_FILES = FileList[
  'README.txt',
  'LICENSE.txt',
  'lib/**/*', 
  'examples/**/*',
  'test/**/*',
  'bin/*'
]
RCOV_DIR = 'rcov'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name               = 'rasta'
    s.files              = PKG_FILES.to_a
    s.platform           = Gem::Platform::CURRENT
    s.email              = 'hugh_mcgowan@yahoo.com' 
    s.has_rdoc           = false 
    s.homepage           = "http://github.com/hmcgowan/rasta"
    s.summary            = "Rasta"
    s.description        = <<-EOF
        Rasta is a keyword-driven test framework using spreadsheets
        to drive test automation. It is loosely based on FIT - tables
        define test parameters which call your test fixture. As the
        test runs, the spreadsheet is updated with test results.
    EOF
    s.bindir             = 'bin'
    s.executables       << 'rasta'
    s.default_executable = 'rasta'
    s.authors            = ['Hugh McGowan']

    s.add_dependency "rspec", [">= 1.1.11"]
    s.add_dependency "roo", [">= 1.1.11"]
    s.add_dependency "user-choices", [">= 1.1.6"]
    
    s.has_rdoc = true
    s.rdoc_options = ["--main", "README"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
 
Spec::Rake::SpecTask.new('test') do |t|
  t.libs << File.join(File.dirname(__FILE__), 'lib')
  t.spec_files = FileList['spec/**/*_spec.rb']
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Rasta'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
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

