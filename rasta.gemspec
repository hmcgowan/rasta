# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rasta}
  s.version = "1.0.0"
  s.platform = %q{universal-darwin-9}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Hugh McGowan"]
  s.date = %q{2009-01-31}
  s.default_executable = %q{rasta}
  s.description = %q{Rasta is a keyword-driven test framework using spreadsheets to drive test automation. It is loosely based on FIT - tables define test parameters which call your test fixture. As the test runs, the spreadsheet is updated with test results.}
  s.email = %q{hugh_mcgowan@yahoo.com}
  s.executables = ["rasta"]
  s.files = ["README.txt", "LICENSE.txt", "lib/rasta", "lib/rasta/extensions", "lib/rasta/extensions/roo_extensions.rb", "lib/rasta/extensions/rspec_extensions.rb", "lib/rasta/fixture", "lib/rasta/fixture/base_fixture.rb", "lib/rasta/fixture/page_fixture.rb", "lib/rasta/fixture/rasta_fixture.rb", "lib/rasta/fixture/rspec_helpers.rb", "lib/rasta/fixture/table_fixture.rb", "lib/rasta/fixture_runner.rb", "lib/rasta/formatter", "lib/rasta/formatter/spreadsheet_formatter.rb", "lib/rasta/html.rb", "lib/rasta/spreadsheet.rb", "lib/rasta.rb", "examples/fixtures", "examples/fixtures/ColumnLayout.rb", "examples/fixtures/crud", "examples/fixtures/crud/CrudClass.rb", "examples/fixtures/crud/CrudFixture.rb", "examples/fixtures/HtmlRegistration.rb", "examples/fixtures/MathFunctions.rb", "examples/fixtures/StringFunctions.rb", "examples/html", "examples/rasta_fixture.ods", "examples/rasta_fixture.old", "examples/rasta_fixture.old/Configurations2", "examples/rasta_fixture.old/Configurations2/accelerator", "examples/rasta_fixture.old/Configurations2/accelerator/current.xml", "examples/rasta_fixture.old/Configurations2/floater", "examples/rasta_fixture.old/Configurations2/images", "examples/rasta_fixture.old/Configurations2/images/Bitmaps", "examples/rasta_fixture.old/Configurations2/menubar", "examples/rasta_fixture.old/Configurations2/popupmenu", "examples/rasta_fixture.old/Configurations2/progressbar", "examples/rasta_fixture.old/Configurations2/statusbar", "examples/rasta_fixture.old/Configurations2/toolbar", "examples/rasta_fixture.old/content.xml", "examples/rasta_fixture.old/META-INF", "examples/rasta_fixture.old/META-INF/manifest.xml", "examples/rasta_fixture.old/meta.xml", "examples/rasta_fixture.old/mimetype", "examples/rasta_fixture.old/settings.xml", "examples/rasta_fixture.old/styles.xml", "examples/rasta_fixture.old/Thumbnails", "examples/rasta_fixture.old/Thumbnails/thumbnail.png", "examples/rasta_fixture.xls", "examples/tests_in_column_layout.xls", "examples/watir_example.xls", "bin/rasta"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/hmcgowan/rasta}
  s.rdoc_options = ["--main", "README", "--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Rasta}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec>, [">= 1.1.11"])
      s.add_runtime_dependency(%q<roo>, [">= 1.1.11"])
      s.add_runtime_dependency(%q<user-choices>, [">= 1.1.6"])
    else
      s.add_dependency(%q<rspec>, [">= 1.1.11"])
      s.add_dependency(%q<roo>, [">= 1.1.11"])
      s.add_dependency(%q<user-choices>, [">= 1.1.6"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.1.11"])
    s.add_dependency(%q<roo>, [">= 1.1.11"])
    s.add_dependency(%q<user-choices>, [">= 1.1.6"])
  end
end
