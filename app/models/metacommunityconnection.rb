# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Metacommunityconnection < ActiveRecord::Base
  CONNECTIONTYPES = {'leaders' => 'Composed of leaders of included communities',
                     'members' => 'Composed of members of included communities',
                     'wantstojoin' => 'Composed of users that want to join the included communities',
                     'interest' => 'Composed of users that are interested in the included communities',
                     'invited' => 'Composed of those that have been invited to the included communities',
                     'joined' => 'Composed of members and leaders of included communities',
                     'interested' => 'Composed of leaders, interest, and wantstojoin in the included communities'}
           
  belongs_to :metacommunity, :class_name => "Community"
  belongs_to :includedcommunity,     :class_name => "Community"


  def makeconnection_by_connectiontype?(type_of_connection)
    return true if(type_of_connection == 'all')
    case self.connectiontype
    when 'leaders'
      (type_of_connection == 'leader')
    when 'members'
      (type_of_connection == 'member')
    when 'wantstojoin'
      (type_of_connection == 'wantstojoin')
    when 'interest'
      (type_of_connection == 'interest')
    when 'invited'
      (type_of_connection == 'invited')
    when 'joined'
      (type_of_connection == 'member' or type_of_connection == 'leader')
    when 'interested'
      (type_of_connection == 'leader' or type_of_connection == 'wantstojoin' or type_of_connection == 'interest')
    else
      false
    end
  end
  
end