# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module ReportsHelper
  
  # this method is to keep a complicated nil check out of the publishedcontent view
  def publishedcontent_number(hash,key,value)
    if(hash[key].nil?)
      return 0
    elsif(hash[key][value].nil?)
      return 0
    else
      return hash[key][value]
    end
  end
  
  # this method will keep divide by zero exceptions from happening
  def publishedcontent_ratio(hash,key,divisor_value,dividend_value)
    dividend = publishedcontent_number(hash,key,dividend_value)
    if(dividend == 0)
      ratio = 0
    else
      divisor = publishedcontent_number(hash,key,divisor_value)
      ratio = divisor.to_f/dividend.to_f
    end
    
    return number_to_percentage(ratio*100,:precision => 0)
    
  end
  
  
end