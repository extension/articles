# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module Aae::FeedsHelper
  
  def get_date(date_var)
    return date_var if date_var.class == Time
    date_array = ParseDate.parsedate(date_var)
    Time.local(*date_array)
  end
  
  def date_format(date)
    date.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
  
end
