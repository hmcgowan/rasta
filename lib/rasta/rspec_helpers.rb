module TestCaseHelperMethods
  @@actual_value = nil
  
  def rspec_test_case
    if @exception_expected
      if @exception
        lambda{ @fixture.send @header }.should raise_error(@exception, @exception_message)
      else
        lambda{ @fixture.send @header }.should raise_error
      end
    else
      lambda{ @@actual_value = @fixture.send @header }.should_not raise_error
      if @cell == 'nil'
        expected_value = nil
      else
        expected_value = @cell
      end
      case expected_value
      when /^\s*<=(.+)/
        @@actual_value.should be_less_than_or_equal_to($1.to_f)
      when /^\s*>=(.+)/
        @@actual_value.should be_greater_than_or_equal_to($1.to_f)
      when /^\s*<(.+)/
        @@actual_value.should be_less_than($1.to_f)
      when /^\s*>(.+)/
        @@actual_value.should be_greater_than($1.to_f)
      when Regexp
        @@actual_value.should =~ expected_value
      else
        @@actual_value.should == expected_value
      end
    end
  end
end 