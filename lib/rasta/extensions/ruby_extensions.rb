class String 
  ARRAY  = /\A\s*\[.+\]\s*\Z/ms
  HASH   = /\A\s*\{.+\}\s*\Z/ms
  BOOL   = /\A\s*(true|false)\s*\Z/i
  REGEXP = /\A\s*(\/.+\/)\w*\s*\Z/ms
  NUMBER = /\A\s*-?\d+\.??\d*?\s*\Z/

  # Given a string, find the closest Ruby data type
  def to_datatype
    self.strip!
    case self
    when ARRAY, HASH, BOOL, REGEXP
      eval(self)
    when NUMBER
      # if the number starts with 0 and not preceded
      # by a decimal then treat as a string. This 
      # makes sure things like zip codes are properly 
      # handled. Not sure if there's a better way.
      # Otherwise eval to convert to the proper number datatype
      self =~ /^0\d/ ? self : eval(self)  
    else
      self
    end
  end   
end