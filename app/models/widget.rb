# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widget < ActiveRecord::Base

  has_many :user_roles
  has_many :assignees, :source => :user, :through => :user_roles, :conditions => "role_id = #{Role.widget_auto_route.id} and users.retired = false"


end
