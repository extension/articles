# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
class EmailAddress
  
  attr_accessor :email_address, :parsed_email_address, :is_valid_address
  
  def initialize(email_address)
    @email_address = email_address
    begin
      @parsed_email_address = TMail::Address.parse(email_address)
    rescue TMail::SyntaxError
      return nil
    else
      return self
    end
  end
    
  def base_domain
    @parsed_email_address.domain.split('.').slice(-2, 2).join(".") rescue nil
  end
    
  def domain
    @parsed_email_address.domain
  end
    
  def local
    @parsed_email_address.local
  end
  
  def inspect
    @email_address
  end
  
  # maintaining because it's used elsewhere
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
