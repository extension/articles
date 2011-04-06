# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class EmailAlias < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :community
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_modifier, :class_name => "User", :foreign_key => "last_modified_by"
  
  validates_presence_of :alias_type, :mail_alias, :destination
  
  # alias_types
  INDIVIDUAL_FORWARD         = 1
  INDIVIDUAL_FORWARD_CUSTOM  = 2
  INDIVIDUAL_GOOGLEAPPS      = 3
  INDIVIDUAL_ALIAS           = 4
  COMMUNITY_GOOGLEAPPS       = 101
  COMMUNITY_NOWHERE          = 102
  SYSTEM_FORWARD             = 201
  SYSTEM_ALIAS               = 202
  
  
  before_validation  :set_values_from_association  
  before_save  :set_values_from_association

  def set_values_from_association
    
    if(!self.user_id.blank? and self.user_id > 0  and self.user_id != User.systemuserid )
      
      # set alias to eXtensionID string?
      self.disabled = !(self.user.is_validuser?)
        
      if([INDIVIDUAL_FORWARD,INDIVIDUAL_FORWARD_CUSTOM,INDIVIDUAL_GOOGLEAPPS].include?(self.alias_type))          
        self.mail_alias = self.user.login
      end
    
      if(self.alias_type == INDIVIDUAL_FORWARD)
        if (self.user.email =~ /extension\.org$/i)
          self.alias_type = INDIVIDUAL_FORWARD_CUSTOM
        else
          self.destination = self.user.email
        end
      elsif(self.alias_type == INDIVIDUAL_GOOGLEAPPS)
        self.destination = "#{self.user.login}@#{AppConfig.configtable['googleapps_domain']}"
      elsif(self.alias_type == INDIVIDUAL_ALIAS or self.alias_type == SYSTEM_ALIAS)
        self.destination = self.user.login
      end
    end
    
    if(!self.community_id.blank? and self.community_id > 0)
      if(self.alias_type == COMMUNITY_GOOGLEAPPS)
        self.disabled = false
        self.mail_alias = self.community.shortname
        self.destination = "#{self.community.shortname}@#{AppConfig.configtable['googleapps_domain']}"
      else
        self.disabled = true
        self.mail_alias = self.community.shortname
        self.destination = "noreply"
      end
    end
    
    return true
  end
  
  def self.mail_alias_in_use?(mail_alias,checkobject=nil)
    conditions = "mail_alias = '#{mail_alias}'"
    if(checkobject)
      if(checkobject.is_a?(Community))
        conditions += " AND community_id <> #{checkobject.id}"
      end
    end
    count = EmailAlias.count(:conditions => conditions)
    return (count > 0)
  end
    
    
  
end