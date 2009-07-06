require 'rasta/fixture/rasta_fixture'
require 'rasta/fixture/rspec_helpers'

# Store the whole worksheet page in a single hash
module Rasta
  module Fixture
    module RastaPageFixture
      include RastaFixture
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

