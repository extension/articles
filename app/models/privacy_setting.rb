# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
class PrivacySetting < ActiveRecord::Base
  belongs_to :user
  
  
  KNOWN_ITEMS = ['email','phone','title','position','institution','location','county','interests','time_zone']
  
  ITEM_LABELS = {'email' => 'Email Address',
                      'phone' => 'Phone Number',
                      'title' => 'Title',
                      'position' => 'Position',
                      'institution' => 'Institution',
                      'location' => 'Location',
                      'county' => 'County',
                      'interests' => 'Interests',
                      'time_zone' => 'Time zone'}
                      
                      
  named_scope :showpublicly, :conditions => {:is_public => 1}
  
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def find_or_create_by_user_and_item(user,item)  
      if(setting = self.find_by_user_id_and_item(user.id,item))
        return setting
      else
        return self.create(:user => user, :item => item)
      end
    end
      
  end
    
end