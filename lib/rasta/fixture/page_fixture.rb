require 'rasta/fixture/abstract_fixture'
require 'rasta/fixture/rspec_helpers'

module Rasta
  module Fixture
    module RastaHashFixture < RastaFixture
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

