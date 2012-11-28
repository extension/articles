# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :category
  
  validates_presence_of :user, :message => "can't be blank"
  validates_presence_of :role, :message => "can't be blank"
  
  def to_s
    return 'Unidentified Role' unless role
    return role.name
  end
  
end
