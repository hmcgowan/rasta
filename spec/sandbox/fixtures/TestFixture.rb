require 'lib/rasta/fixture/rasta_fixture'

class FixtureA
  include Rasta::Fixture::RastaFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end

class FixtureB
  include Rasta::Fixture::RastaFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end


