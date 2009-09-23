# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'TMail'
class EmailAddress
  
  def self.is_valid_address?(email_address)
    begin
      TMail::Address.parse(email_address)
    rescue TMail::SyntaxError
      return false
    else
      return true
    end
  end
  
end
