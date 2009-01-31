$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
 
require 'rubygems'
require 'lib/rasta/version'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

PKG_NAME = Rasta::VERSION::NAME
PKG_VERSION = Rasta::VERSION::STRING
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
    s.name               = PKG_NAME
    s.version            = PKG_VERSION
    s.files              = PKG_FILES.to_a
    s.platform           = Gem::Platform::CURRENT
    s.author             = 'Hugh McGowan'
    s.email              = 'hugh_mcgowan@yahoo.com' 
    s.has_rdoc           = false 
    s.homepage           = Rasta::VERSION::URL
    s.summary            = Rasta::VERSION::DESCRIPTION
    s.description        = <<-EOF
        Rasta is a keyword-driven test framework using spreadsheets
        to drive test automation. It is loosely based on FIT - tables
        define test parameters which call your test fixture. As the
        test runs, the spreadsheet is updated with test results.
    EOF
    s.bindir             = 'bin'
    s.executables       << 'rasta'
    s.default_executable = 'rasta'

    s.add_dependency "rspec", [">= 1.1.11"]
    s.add_dependency "roo", [">= 1.1.11"]
    s.add_dependency "user-choices", [">= 1.1.6"]
    
    s.has_rdoc = true
    s.rdoc_options = ["--main", "README"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
 
desc "Run RSpec tests"
Spec::Rake::SpecTask.new('test') do |t|
  t.libs << File.join(File.dirname(__FILE__), 'lib')
  t.spec_files = FileList['spec/**/*_spec.rb']
end
 
desc "Run RCov"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.libs << File.join(File.dirname(__FILE__), 'lib')
  t.rcov = true
  t.rcov_dir = RCOV_DIR
  t.rcov_opts << '--text-report'
  t.rcov_opts << '--exclude spec'
end
 
desc "Build RDocs"
task :rdoc do
  system "rdoc --main README --title 'Rasta RDoc' README lib"
end

desc "Install latest gem"
task :install => :gem do 
  gem = "ruby #{Config::CONFIG['bindir']}\\gem"
  begin
    sh "#{gem} uninstall -x rasta -v #{PKG_VERSION}"
  rescue
    puts "Nothing to uninstall..."
  ensure
    sh "#{gem} install pkg\\#{package.gem_file}"
  end
end

