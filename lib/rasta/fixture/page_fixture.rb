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
      
      def with_each_cell(cell)
        send_record_to_spreadsheet_formatter(cell.name)
        return if (cell.empty? || ignore?(cell))
        if pending?(cell)
          @test_fixture.pending = cell.value
        elsif ruby_method?(cell)
          call_test_fixture_method(cell)
        end
      end
      
      def pending
        @rasta[:pending]
      end
      
    end 
  end  
end

