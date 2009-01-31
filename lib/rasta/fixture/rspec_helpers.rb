module TestCaseHelperMethods
  @@actual_value = nil
  
  def run_rspec_test_case
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
      when /^(<=|>=|>|<)(.+)/  
        eval("@@actual_value.should #{$1} #{$2}")
      when Regexp
        @@actual_value.should =~ expected_value
      else
        @@actual_value.should == expected_value
      end
    end
  end
end 