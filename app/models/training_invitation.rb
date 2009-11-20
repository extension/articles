# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class TrainingInvitation < ActiveRecord::Base
  belongs_to :user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  validate :validate_email_address, :validate_no_existing_account
  validates_uniqueness_of :email
    
  def validate_email_address
    errors.add_to_base("Must be a valid email address") unless EmailAddress.is_valid_address?(self.email)
  end  
  
  def validate_no_existing_account
    if(user = User.find_by_email(self.email))
      errors.add_to_base("Already has an eXtensionID")
      return false
    else
      return true
    end  
  end
end