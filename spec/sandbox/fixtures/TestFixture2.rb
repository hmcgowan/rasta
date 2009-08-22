require 'lib/rasta/fixture/classic_fixture'

class FixtureC
  include Rasta::Fixture::RastaClassicFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end

class FixtureD
  include Rasta::Fixture::RastaClassicFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end
