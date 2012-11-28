# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'

class PublicUser < Account
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/
  attr_protected :password 
  
  def first_name
    if(first_name = read_attribute(:first_name))
      return first_name
    else
      return 'Anonymous'
    end
  end
  
  def last_name
    if(last_name = read_attribute(:last_name))
      return last_name
    else
      return 'Guest'
    end
  end
  

end