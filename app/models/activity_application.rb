# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class ActivityApplication < ActiveRecord::Base
  has_many :activities
  has_many :update_times, :as => :datasource
    
  # sourcetypes
  
  NONE = 0
  PEOPLE = 1
  LOGINONLY = 2
  DATABASE = 3
  WIKIDATABASE = 4
  FILE = 5

  named_scope :active, {:conditions => {:isactivesource => true}}
  named_scope :activitysources, {:conditions => ["activitysourcetype IN (#{ActivityApplication::DATABASE},#{ActivityApplication::WIKIDATABASE},#{ActivityApplication::FILE})"]}
  
  def name
    return displayname
  end
  
    
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  
  def self.finduri(uri)
     return find(:first, :conditions => ["trust_root_uri = ? or CONCAT(trust_root_uri,'/') = ?",uri,uri])
  end
  
  def self.local
    find(1)
  end
    
  def self.find_by_id_or_shortname(value)
    #TODO - there possibly may be an issue here with the conditional
   if(value.to_i != 0)
     # assume id value
     checkfield = 'id'
   else
     checkfield = 'shortname'
   end

   return self.send("find_by_#{checkfield}",value)
  end
    
    
end
