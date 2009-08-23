require 'lib/rasta/fixture/classic_fixture'

class FixtureA
  include Rasta::Fixture::ClassicFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end

class FixtureB
  include Rasta::Fixture::ClassicFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end


