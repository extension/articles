# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class ActivityApplication < ActiveRecord::Base
  has_many :activities
  has_many :activity_objects
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
  
  def isactivitysource?
    activitysources = [ActivityApplication::DATABASE, ActivityApplication::WIKIDATABASE, ActivityApplication::FILE]
    if(activitysources.include?(self.activitysourcetype))
      return true
    else
      return false
    end
  end
  
  
  def get_activityobjects(refreshall=false,retrievedby = nil)  
    noerrors = true
    return false if !(self.isactivitysource?)
    if(retrievedby.nil?)
      retrievedby = User.systemuser
    end
    baseoptions = {:activityapplication => self, :refreshall => refreshall}
    case self.activitysourcetype    
    when ActivityApplication::WIKIDATABASE
      datatypes = ['pages','deletedpages']
      # todo 'published' for the cop wiki
    when ActivityApplication::DATABASE
      case self.shortname
      when 'faq'
        datatypes = ['questions']
        # todo 'published' for faq
      when 'events'
        datatypes = ['eventitems']
      when 'aae'
        datatypes = ['submittedquestions']
      when 'justcode'
        datatypes = ['changesets']
      else
        return false
      end
    when ActivityApplication::FILE
      case self.shortname
      when 'lists'
        datatypes = ['posts']
      else
        return false
      end
    else
      return false
    end    

    datatypes.each do |datatype|
      updatetime = UpdateTime.find_or_create(self,datatype)
      lastupdated = ActivityObject.retrieve_objects(baseoptions.merge({:datatype => datatype, :last_activitysource_at => updatetime.last_datasourced_at}))
      if(lastupdated)
        #stop logging success for now
        #ActivityEvent.log_event(:activity_application => self,:event => ActivityEvent::RETRIEVE_DATA_SUCCESS,:user => retrievedby,:eventdata => {:datatype => datatype, :lastupdated => lastupdated})            
        updatetime.update_attribute(:last_datasourced_at,lastupdated)
      else
        noerrors = false
        ActivityEvent.log_event(:activity_application => self,:event => ActivityEvent::RETRIEVE_DATA_FAILURE,:user => retrievedby,:eventdata => {:datatype => datatype})            
      end
    end

    return noerrors
  end
  
  def get_activity(refreshall=false,retrievedby = nil)
    returninformation = {}
    return returninformation if !(self.isactivitysource?)
    if(retrievedby.nil?)
      retrievedby = User.systemuser
    end
    baseoptions = {:activityapplication => self, :refreshall => refreshall}
    case self.activitysourcetype    
    when ActivityApplication::WIKIDATABASE
      datatypes = ['editpage']
      if(self.shortname == 'copwiki')
        datatypes << 'publish'
      end 
    when ActivityApplication::DATABASE
      case self.shortname
      when 'faq'
        datatypes = ['edit','publish']
      when 'events'
        datatypes = ['edit']
      when 'aae'
        datatypes = ['submission','activity']
      when 'justcode'
        datatypes = ['changeset']
      else
        return returninformation
      end
    else
      return false
    end
        
    datatypes.each do |datatype|
      updatetime = UpdateTime.find_or_create(self,datatype)
      lastupdated = Activity.retrieve_activity(baseoptions.merge({:datatype => datatype, :last_activitysource_at => updatetime.last_datasourced_at}))
      returninformation[datatype] = lastupdated
      if(lastupdated)
        #stop logging success for now
        #ActivityEvent.log_event(:activity_application => self,:event => ActivityEvent::RETRIEVE_DATA_SUCCESS,:user => retrievedby,:eventdata => {:datatype => datatype, :lastupdated => lastupdated})            
        updatetime.update_attribute(:last_datasourced_at,lastupdated)
      else
        ActivityEvent.log_event(:activity_application => self,:event => ActivityEvent::RETRIEVE_DATA_FAILURE,:user => retrievedby,:eventdata => {:datatype => datatype})            
      end
    end
    
    return returninformation
  end
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def finduri(uri)
       return find(:first, :conditions => ["trust_root_uri = ? or CONCAT(trust_root_uri,'/') = ?",uri,uri])
    end
    
    def local
      find(1)
    end
    
  end
end
