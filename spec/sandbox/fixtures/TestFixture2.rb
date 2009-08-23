require 'lib/rasta/fixture/classic_fixture'

class FixtureC
  include Rasta::Fixture::ClassicFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end

class FixtureD
  include Rasta::Fixture::ClassicFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end
