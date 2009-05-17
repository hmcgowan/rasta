# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rasta}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Hugh McGowan"]
  s.date = %q{2009-05-16}
  s.default_executable = %q{rasta}
  s.description = %q{Rasta is a keyword-driven test framework using spreadsheets to drive test automation. It is also loosely based on FIT - tables define test parameters which call your test fixture. As the test runs, the spreadsheet is updated with test results.}
  s.email = %q{hugh_mcgowan@yahoo.com}
  s.executables = ["rasta"]
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["bin/rasta", "lib/rasta", "lib/rasta/bookmark.rb", "lib/rasta/extensions", "lib/rasta/extensions/roo_extensions.rb", "lib/rasta/extensions/rspec_extensions.rb", "lib/rasta/extensions/ruby_extensions.rb", "lib/rasta/fixture", "lib/rasta/fixture/base_fixture.rb", "lib/rasta/fixture/metrics.rb", "lib/rasta/fixture/page_fixture.rb", "lib/rasta/fixture/rasta_fixture.rb", "lib/rasta/fixture/rspec_helpers.rb", "lib/rasta/fixture/table_fixture.rb", "lib/rasta/fixture_runner.rb", "lib/rasta/formatter", "lib/rasta/formatter/spreadsheet_formatter.rb", "lib/rasta/resources", "lib/rasta/resources/rasta.css", "lib/rasta/resources/tabber-minimized.js", "lib/rasta.rb", "spec/bookmark_spec.rb", "spec/fixture_runner_spec.rb", "spec/google_stub_spec.rb", "spec/metrics_spec.rb", "spec/roo_extensions_spec.rb", "spec/ruby_extensions_spec.rb", "spec/sandbox", "spec/sandbox/base_fixture_spec.rbx", "spec/sandbox/fixtures", "spec/sandbox/fixtures/TestFixture.rb", "spec/sandbox/rasta_fixture_spec.rbx", "spec/sandbox/spreadsheets", "spec/sandbox/spreadsheets/rasta_fixture.xls", "spec/sandbox/spreadsheets/spreadsheet_parsing.xls", "spec/spec_helper.rb", "README", "LICENSE"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/hmcgowan/rasta}
  s.rdoc_options = ["--main", "README", "--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rasta}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Rasta}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec>, [">= 1.1.11"])
      s.add_runtime_dependency(%q<hmcgowan-roo>, [">= 1.3.1"])
      s.add_runtime_dependency(%q<user-choices>, [">= 1.1.6"])
    else
      s.add_dependency(%q<rspec>, [">= 1.1.11"])
      s.add_dependency(%q<hmcgowan-roo>, [">= 1.3.1"])
      s.add_dependency(%q<user-choices>, [">= 1.1.6"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.1.11"])
    s.add_dependency(%q<hmcgowan-roo>, [">= 1.3.1"])
    s.add_dependency(%q<user-choices>, [">= 1.1.6"])
  end
end
