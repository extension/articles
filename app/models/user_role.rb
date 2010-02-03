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
  belongs_to :widget
  
  validates_presence_of :user, :message => "can't be blank"
  validates_presence_of :role, :message => "can't be blank"
  
  def to_s
    return 'Unidentified Role' unless role
    
    case role.name
    when Role::AUTO_ROUTE
      return 'Receive Auto-Routed Questions'
    when Role::WIDGET_AUTO_ROUTE    
      return role.name + " (<a href='/widgets/aae/view/#{self.widget.id}'>#{self.widget.name} widget</a>)"
    else
      return role.name
    end  
  end
  
end
