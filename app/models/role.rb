# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Role < ActiveRecord::Base
  has_many :user_roles
  has_many :users, :through => :user_roles

  UNCATEGORIZED_QUESTION_WRANGLER = "Uncategorized Question Wrangler"
  ESCALATION = "Receive Escalations"
  AUTO_ROUTE = 'Auto Route Questions'
  ADMINISTRATOR = 'Administrator'
  COMMUNITY_ADMINISTRATOR = 'Community Administrator'
  WIDGET_AUTO_ROUTE = 'Auto Route Widget Questions'
  
  def self.widget_auto_route
    find(:first, :conditions => "name = '#{WIDGET_AUTO_ROUTE}'")
  end
  
  
end
