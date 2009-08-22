require 'rasta/fixture/classic_fixture'

class StringFunctions 
  include Rasta::Fixture::RastaClassicFixture
  attr_accessor :phrase, :searchterm
  def chop
    phrase.chop
  end
  def reverse
    phrase.reverse
  end
  def contains_term?
    phrase[searchterm] != nil
  end
  def length
    phrase.length
  end
end
