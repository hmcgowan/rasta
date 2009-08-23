require 'rasta/fixture/abstract_fixture'

# Store the whole worksheet page in a single hash
module Rasta
  module Fixture
    module PageFixture
      include Rasta::Fixture::AbstractFixture
      attr_accessor :rasta
      
      def before_each_record(sheet)
        super
        @rasta = {}
      end
      
      def set_test_fixture_value(cell)
        @rasta[cell.header.intern] = cell.value
      end
      
    end 
  end  
end

