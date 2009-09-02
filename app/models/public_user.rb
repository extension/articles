# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'

class PublicUser < ActiveRecord::Base
  has_many :submitted_questions
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/
  
  # override email write
  def email=(emailstring)
    write_attribute(:email, emailstring.mb_chars.downcase)
  end
  
  def fullname 
    return "#{self.first_name} #{self.last_name}"
  end
  
end