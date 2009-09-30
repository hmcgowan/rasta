require 'rasta/fixture/abstract_fixture'

module Rasta
  module Fixture
    module ActionFixture
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
