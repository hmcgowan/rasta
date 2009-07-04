module Rasta
  module Fixture
    class Metrics
      attr_accessor :attribute_count, :method_count, :record_count, :cell_count
      def initialize
        reset_page_counts
        reset_record_counts
      end
      # Counts tracked on a worksheet scope
      def reset_page_counts
        @record_count = 0
      end
      # Counts tracked on a record scope
      def reset_record_counts
        @attribute_count = 0
        @method_count = 0
        @cell_count = 0
      end
      def inc(attribute_name)
         eval("@#{attribute_name.to_s} += 1")
      end
    end
  end        
end        