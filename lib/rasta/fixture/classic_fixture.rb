require 'rasta/fixture/abstract_fixture'

module Rasta
  module Fixture
    module RastaClassicFixture 
      include Rasta::Fixture::AbstractFixture
      attr_accessor :pending, :description, :comment

      def set_test_fixture_value(cell)
        @metrics.inc(:attribute_count)
        @test_fixture.send("#{cell.header}=", cell.value)
      end
      
    end 
  end  
end

