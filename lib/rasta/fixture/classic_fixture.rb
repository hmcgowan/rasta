require 'rasta/fixture/abstract_fixture'

module Rasta
  module Fixture
    module ClassicFixture 
      include Rasta::Fixture::AbstractFixture
      attr_accessor :pending, :description, :comment

      def set_test_fixture_value(cell)
        @metrics.inc(:attribute_count)
        @test_fixture.send("#{cell.header}=", cell.value)
      end

      def with_each_cell(cell)
        send_record_to_spreadsheet_formatter(cell.name)
        return if (cell.empty? || ignore?(cell))
        if pending?(cell)
          @test_fixture.pending = cell.value
        elsif ruby_attribute?(cell)
          set_test_fixture_value(cell)
        elsif ruby_method?(cell)
          call_test_fixture_method(cell)
        else 
          raise "Not sure how to handle cell #{cell.name} - not a method or class attribute"
        end
      end
      
    end 
  end  
end

