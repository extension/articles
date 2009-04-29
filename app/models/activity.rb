# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'digest/sha1'
require 'ipaddr'
class Activity < ActiveRecord::Base
  extend ConditionExtensions
  extend GoogleVisualization
  extend DataImportActivity

  EARLIEST_TRACKED_ACTIVITY_DATE = '2005-12-01 00:00:00'
  
  #### PRIVACY SETTINGS
  
  PRIVATE = 100
  PROTECTED = 101
  PUBLIC = 102
  

  #### activity types
  LOGIN = 1
  INFORMATION = 2
  AAE = 3
  PEOPLE = 4
  COMMUNITY = 5
  
  #### activity codes  
  SIGNUP = 101
  INVITATION = 102
  VOUCHED_BY = 103
  VOUCHED_FOR = 104
  UPDATE_PROFILE = 105
  LOGIN_PASSWORD = 106
  LOGIN_OPENID = 107
  LOGIN_OPENID_EXTERNAL = 108
  INVITATION_ACCEPTED = 109
  CREATED_COMMUNITY = 110
  EDIT = 111
  
  # COMMUNITY
  COMMUNITY_ACTIVITY = 200
  COMMUNITY_ACTIVITY_START = 201
  COMMUNITY_ACTIVITY_END = 599
  
  COMMUNITY_JOIN = 201
  COMMUNITY_WANTSTOJOIN = 202
  COMMUNITY_LEFT= 203
  COMMUNITY_INVITATION= 204
  COMMUNITY_ACCEPT_INVITATION= 205
  COMMUNITY_DECLINE_INVITATION= 206
  COMMUNITY_NOWANTSTOJOIN = 207
  COMMUNITY_INTEREST = 208
  COMMUNITY_NOINTEREST = 209
  
  COMMUNITY_INVITEDASLEADER = 210
  COMMUNITY_INVITEDASMEMBER = 211
  COMMUNITY_ADDEDASLEADER = 212
  COMMUNITY_ADDEDASMEMBER = 213
  COMMUNITY_REMOVEDASLEADER = 214
  COMMUNITY_REMOVEDASMEMBER = 215
  COMMUNITY_INVITATIONRESCINDED = 216
  
  COMMUNITY_INVITELEADER = 301
  COMMUNITY_INVITEMEMBER = 302
  COMMUNITY_ADDLEADER = 303
  COMMUNITY_ADDMEMBER = 304
  COMMUNITY_REMOVELEADER = 305
  COMMUNITY_REMOVEMEMBER = 306
  COMMUNITY_RESCINDINVITATION = 307
  COMMUNITY_INVITEREMINDER = 308
  
  COMMUNITY_UPDATE_INFORMATION = 401
  COMMUNITY_CREATED_LIST = 402
  COMMUNITY_TAGGED = 403

  LIST_POST = 501
  
  # AAE
  AAE_RESOLVE = 601
  AAE_ASSIGN = 602
  AAE_REJECT = 603
  AAE_OTHER = 604
  AAE_NOANSWER = 605
  AAE_SUBMISSION_PUBSITE = 610
  AAE_SUBMISSION_WIDGET = 611
  AAE_SUBMISSION_OTHER = 612
  
  # INFORMATION
  INFORMATION_EDIT = 701
  INFORMATION_COMMENT = 702
  INFORMATION_PUBLISH = 703
  INFORMATION_CHANGESET = 704
  
    
  ACTIVITY_LOCALE_STRINGS = {
    LOGIN_PASSWORD => 'login',
    LOGIN_OPENID => 'login',
    INFORMATION_EDIT => 'information_edit',
    INFORMATION_COMMENT => 'information_comment',
    INFORMATION_PUBLISH => 'information_publish',
    INFORMATION_CHANGESET => 'information_changeset',
    AAE_RESOLVE => 'aae_resolve',
    AAE_ASSIGN => 'aae_assign',
    AAE_REJECT => 'aae_reject',
    AAE_OTHER => 'aae_other',
    AAE_NOANSWER => 'aae_noanswer',
    AAE_SUBMISSION_PUBSITE => 'aae_submission_pubsite',
    AAE_SUBMISSION_WIDGET => 'aae_submission_widget',
    SIGNUP => 'signup',
    INVITATION => 'invitation',
    VOUCHED_BY => 'vouched_by',
    VOUCHED_FOR => 'vouched_for',
    UPDATE_PROFILE => 'updateprofile',
    INVITATION_ACCEPTED => 'acceptedinvitation',
    CREATED_COMMUNITY=> 'community_create',
    COMMUNITY_JOIN => 'community_join',
    COMMUNITY_WANTSTOJOIN => 'community_wantstojoin',
    COMMUNITY_LEFT => 'community_left',
    COMMUNITY_INVITATION => 'unknown',
    COMMUNITY_ACCEPT_INVITATION => 'community_accept_invitation',
    COMMUNITY_DECLINE_INVITATION => 'community_decline_invitation',
    COMMUNITY_NOWANTSTOJOIN => 'community_nowantstojoin',
    COMMUNITY_INTEREST => 'community_interest',
    COMMUNITY_NOINTEREST => 'community_nointerest',
    COMMUNITY_INVITEDASLEADER => 'community_invited_leader',
    COMMUNITY_INVITEDASMEMBER => 'community_invited_member',
    COMMUNITY_ADDEDASLEADER => 'community_addedasleader',
    COMMUNITY_ADDEDASMEMBER => 'community_addedasmember',
    COMMUNITY_REMOVEDASLEADER => 'community_removedasleader',
    COMMUNITY_REMOVEDASMEMBER => 'community_removedasmember',
    COMMUNITY_INVITATIONRESCINDED => 'community_invitation_rescinded',
    COMMUNITY_INVITELEADER => 'unknown',
    COMMUNITY_INVITEMEMBER => 'unknown',
    COMMUNITY_ADDLEADER => 'unknown',
    COMMUNITY_ADDMEMBER => 'unknown',
    COMMUNITY_REMOVELEADER => 'unknown',
    COMMUNITY_REMOVEMEMBER => 'unknown',
    COMMUNITY_RESCINDINVITATION => 'unknown',
    COMMUNITY_INVITEREMINDER => 'community_invite_reminder',
    COMMUNITY_UPDATE_INFORMATION => 'community_update_information',
    COMMUNITY_CREATED_LIST => 'community_created_list',
    COMMUNITY_TAGGED => 'community_tagged',
    LIST_POST => 'listpost'
  }
  
  belongs_to :user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :colleague, :class_name => "User", :foreign_key => "colleague_id"
  belongs_to :community
  belongs_to :activity_application
  belongs_to :activity_object
  
  serialize :additionaldata
  
  named_scope :bydate, lambda {|options| {:conditions => build_date_condition(options)} }
  named_scope :displayactivity, :conditions => ["privacy IN (#{Activity::PUBLIC},#{Activity::PROTECTED})"]
  
  named_scope :validusers, {:joins => [:user], :conditions => { :users => ["retired = 0 and vouched = 1 and id != 1"]}}
  
  named_scope :filtered, lambda {|options| useractivity_filter(options)}
  
  named_scope :byactivityoptions, lambda {|options|
    {:conditions => build_activity_conditions(options)}
  }
  
  named_scope :forusers, lambda {|options|
    {:conditions => build_userlimit_condition(options)}
  }
  
  ######
  # location, county, position, institution of user
  named_scope :byuserassociation, lambda {|options|
    {:joins => [:user], :conditions => User.build_association_conditions(options)}
  }
  
  named_scope :location, lambda {|location|
    {:joins => [:user], :conditions => { :users => {:location_id => location.id}}}
  }
  
  named_scope :county, lambda {|county|
    {:joins => [:user], :conditions => { :users => {:county_id => county.id}}}
  }
  
  named_scope :position, lambda {|position|
    {:joins => [:user], :conditions => { :users => {:position_id => position.id}}}
  }
  
  named_scope :institution, lambda {|institution|
    {:joins => [:user], :conditions => { :users => {:institution_id => institution.id}}}
  }
  
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def per_page
      25
    end
    
    def build_community_joins(options)
      communityactivity = options[:communityactivity] || 'member'
      if(communityactivity == 'member')
        return {:user => :communities}
      else
        return nil
      end
    end
    
    def build_community_conditions(options)      
      connectiontype = options[:connectiontype] || 'joined'
      communityactivity = options[:communityactivity] || 'member'

      if(communityactivity == 'community')
        return "#{table_name}.community_id = #{options[:community].id}"
      elsif(communityactivity == 'all')
        # hack! 
        userlist = User.filtered({:community => options[:community], :connectiontype => connectiontype, :dateinterval => 'all'})
        if(userlist.size > 0)
          return "#{table_name}.user_id IN (#{userlist.map(&:id).join(',')}) OR #{table_name}.community_id = #{options[:community].id}"
        else
          return "#{table_name}.community_id = #{options[:community].id}"
        end
      else # member
        return "#{Community.table_name}.id = #{options[:community].id} AND #{Communityconnection.connection_condition(options[:connectiontype])}"
      end
    end
    
    
    def build_communitytype_joins(options)
      communityactivity = options[:communityactivity] || 'member'
      if(communityactivity == 'member')
        return {:user => :communities}
      else
        return :community
      end
    end
    
    def build_communitytype_conditions(options)
      connectiontype = options[:connectiontype] || 'joined'
      communityactivity = options[:communityactivity] || 'member'
      
      if(communityactivity == 'community')
        return "#{Community.communitytype_condition(options[:communitytype])}"
      else
        return "(#{Community.communitytype_condition(options[:communitytype])} AND #{Communityconnection.connection_condition(options[:connectiontype])})"
      end
    end
    
  
    def build_userlimit_condition(options={})
      if(options[:user])
        return "activities.user_id = #{options[:user].id}"
      elsif(options[:person])
        return "activities.user_id = #{options[:person].id}"
      elsif(options[:userlist])
        return"activities.user_id IN (#{options[:userlist].map(&:id).join(',')})"
      else
        return nil
      end
    end
    
    def build_activity_conditions(options={})
      conditionsarray = []
      
      #ipaddress
      if(options[:activityaddress])
        conditionsarray << "#{table_name}.ipaddr LIKE '#{options[:activityaddress]}%'"
      end

      # activity code(s) or activity label (most common case)
      if(options[:activitycode])
        conditionsarray << "#{table_name}.activitycode = #{options[:activitycode]}"
      elsif(options[:activitycodes])
        conditionsarray << "#{table_name}.activitycode IN (#{options[:activitycodes].join(',')})"
      elsif(options[:activity])
        if(activitycodes = self.activity_to_codes(options[:activity]))
          conditionsarray << "#{table_name}.activitycode IN (#{activitycodes.join(',')})"
        end
      end
      
      # activity types(s) or activitygroup label (most common case)
      if(options[:activitytype])
        conditionsarray << "#{table_name}.activitytype = #{options[:activitytype]}"
      elsif(options[:activitytypes])
        conditionsarray << "#{table_name}.activitytype IN (#{options[:activitytypes].join(',')})"
      elsif(options[:activitygroup])
        if(activitytypes = self.activitygroup_to_types(options[:activitygroup]))
          conditionsarray << "#{table_name}.activitytype IN (#{activitytypes.join(',')})"
        end
      end
      
      # narrow to certain activity_applications
      if(options[:activityapplication])
        conditionsarray << "#{table_name}.activity_application_id = #{options[:activityapplication].id}"
      elsif(options[:activityapplications])
        conditionsarray << "#{table_name}.activity_application_id IN (#{options[:activityapplications].map(&:id).join(',')})"
      elsif(options[:appname])
        if(aa = ActivityApplication.find_by_shortname(options[:appname]))
          conditionsarray << "#{table_name}.activity_application_id = #{aa.id}"
        end  
      end # TODO? 'appnames?'
          
      if(!conditionsarray.blank?)
        return conditionsarray.join(' AND ')
      else
        return nil
      end
    end
    
    def build_activityentrytype_condition(options)
      conditions = nil
      # narrow to certain activity_applications
      if(options[:activityentrytype])
        if(entrytype = ActivityObject.label_to_entrytype(options[:activityentrytype]))
          conditions = "#{ActivityObject.table_name}.entrytype = #{entrytype}"
        end
      elsif(options[:activityentrytypes])
        # TODO!
      end
      
      return conditions
    end
    
    def useractivity_filter(options={})
      joins = [:user]
      
      conditions = []
      
      conditions << build_date_condition(options)

      # activity conditions?
      conditions << build_activity_conditions(options)
      
      # specific entrytype?
      if(activityentrytype_condition = build_activityentrytype_condition(options))
        joins << :activity_object
        conditions << activityentrytype_condition
      end
      
      

      if(options[:allactivity].nil? or !options[:allactivity])
        conditions << "#{table_name}.privacy != #{Activity::PRIVATE}"
      end
      
      # activity object type?
      if(options[:community])
        conditions << "#{table_name}.privacy != #{Activity::PRIVATE}"
      end
      
      # TODO:  how much of this check is relevant if looking at a user or userlist?
      if(options[:community])
        joins << build_community_joins(options)
        conditions << build_community_conditions(options)
      elsif(options[:communitytype])
        joins << build_communitytype_joins(options)
        conditions << build_communitytype_conditions(options)
      end

      if(userlimitconditions = build_userlimit_condition(options))
        conditions << userlimitconditions
      else           
        # location, position, institution?
        conditions << User.build_association_conditions(options)
        
        if(options[:allusers].nil? or !options[:allusers])
          #conditions << "#{User.table_name}.retired = 0 and #{User.table_name}.vouched = 1 and #{User.table_name}.id != 1"
          conditions << "#{User.table_name}.retired = 0 and #{User.table_name}.vouched = 1"
        end
      end
            
      return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}  
    end
    
  
    def hourlycount_with_userfilter(options = {},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do       
        datefield = options[:datefield] || AppConfig.configtable['default_datefield'] 
        tz = options[:tz] || AppConfig.configtable['default_timezone']  
        
        if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
          activityhour = "HOUR(CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}'))"
        else
          activityhour = "HOUR(#{table_name}.#{datefield})"
        end
      
        counts = self.filtered(options).count(:all, :group => activityhour)
        activity = {}
        counts.map{|values| activity[values[0].to_i] = values[1].to_i}
        return activity
      end
    end
    
    def weekdaycount_with_userfilter(options = {},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do       
        datefield = options[:datefield] || AppConfig.configtable['default_datefield'] 
        tz = options[:tz] || AppConfig.configtable['default_timezone']  
        
        if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
          activityweekday = "WEEKDAY(CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}'))"
        else
          activityweekday = "WEEKDAY(#{table_name}.#{datefield})"
        end
      
        counts = self.filtered(options).count(:all, :group => activityweekday)
        activity = {}
        returncounts = []
        counts.map{|values| activity[values[0].to_i] = values[1].to_i}
        return activity
      end
    end    
  
    def weekofyearcount_with_userfilter(options = {},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do       
        datefield = options[:datefield] || AppConfig.configtable['default_datefield'] 
        tz = options[:tz] || AppConfig.configtable['default_timezone']  
        
        if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
          activityweekofyear = "WEEK(CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}'),1)"
        else
          activityweekofyear = "WEEK(#{table_name}.#{datefield},1)"
        end
      
        counts = self.filtered(options).count(:all, :group => activityweekofyear)
        activity = {}
        returncounts = []
        counts.map{|values| activity[values[0].to_i] = values[1].to_i}
        return activity
      end
    end
    
    def yearweekcount_with_userfilter(options = {},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do       
        datefield = options[:datefield] || AppConfig.configtable['default_datefield'] 
        tz = options[:tz] || AppConfig.configtable['default_timezone']  
        
        if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
          activityweek = "DATE_FORMAT(CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}'),'%Y-%u')"
        else
          activityweek = "DATE_FORMAT(#{table_name}.#{datefield}, '%Y-%u')"
        end
      
        counts = self.filtered(options).count(:all, :group => activityweek)
        activity = {}
        returncounts = []
        counts.map{|values| activity[values[0]] = values[1].to_i}
        return activity
      end
    end
    
    def yearmonthcount_with_userfilter(options = {},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do       
        datefield = options[:datefield] || AppConfig.configtable['default_datefield'] 
        tz = options[:tz] || AppConfig.configtable['default_timezone']  
        
        if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
          activitymonth = "DATE_FORMAT(CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}'),'%Y-%m')"
        else
          activitymonth = "DATE_FORMAT(#{table_name}.#{datefield}, '%Y-%m')"
        end
      
        counts = self.filtered(options).count(:all, :group => activitymonth)
        activity = {}
        returncounts = []
        counts.map{|values| activity[values[0]] = values[1].to_i}
        return activity
      end
    end
    
    
    def monthcount_with_userfilter(options = {},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do       
        datefield = options[:datefield] || AppConfig.configtable['default_datefield'] 
        tz = options[:tz] || AppConfig.configtable['default_timezone']  
        
        if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
          activitymonth = "MONTH(CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}'))"
        else
          activitymonth = "MONTH(#{table_name}.#{datefield})"
        end
      
        counts = self.filtered(options).count(:all, :group => activitymonth)
        activity = {}
        returncounts = []
        counts.map{|values| activity[values[0].to_i] = values[1].to_i}
        return activity
      end
    end    
    
    def datecount_with_userfilter(options = {},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do       
        datefield = options[:datefield] || AppConfig.configtable['default_datefield'] 
        tz = options[:tz] || AppConfig.configtable['default_timezone']  
        
        if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
          activitydate = "DATE(CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}'))"
        else
          activitydate = "DATE(#{table_name}.#{datefield})"
        end
      
        counts = self.filtered(options).count(:all, :group => activitydate)
        activity = {}
        returncounts = []
        counts.map{|values| activity[Date.parse(values[0])] = values[1].to_i}
        firstday = activity.keys.sort.first
        lastday = activity.keys.sort.last
        return activity
      end
    end    
          
    def count_with_userfilter(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        Activity.filtered(options).count(:all)
      end
    end
    
    def count_signups(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        Activity.filtered(options.merge({:activity => 'signup'})).count(:all,:group => "users.id").size
      end
    end
    
    def count_unique_logins(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        Activity.filtered(options.merge({:activity => 'login'})).count(:all,:group => "users.id").size
      end
    end   
    
    def count_active_users(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        Activity.filtered(options.merge({:activity => 'active'})).count(:all,:group => "users.id").size
      end
    end
    
    def count_unique_users(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        Activity.filtered(options).count(:all,:group => "users.id").size
      end
    end    
    
    def count_unique_communities_with_new_members(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        Activity.filtered(options.merge({:activity => 'joincommunity'})).count(:all,:group => "communities.id").size
      end
    end
    
    def count_unique_users_as_new_community_members(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        Activity.filtered(options.merge({:activity => 'joincommunity'})).count(:all,:group => "users.id").size
      end
    end

    def count_contributions_by_activityentrytype(options={},forcecacheupdate=false)
      # not caching right now
      returnhash = {}
      records = self.filtered(options.merge(:activitygroup => 'contribution')).count(:id,:joins => :activity_object, :group => 'activity_objects.entrytype')
      records.map{|values| returnhash[values[0]] = values[1].to_i}
      return returnhash
    end
    
    def count_unique_activityobjects_by_activityentrytype(options={},forcecacheupdate=false)
      returnhash = {}
      records = self.filtered(options.merge(:activitygroup => 'contribution')).count('DISTINCT(activities.activity_object_id)',:joins => :activity_object, :group => 'activity_objects.entrytype')
      records.map{|values| returnhash[values[0]] = values[1].to_i}
      return returnhash
    end   
    
    def count_uniqueusers_contributing_by_activityentrytype(options={},forcecacheupdate=false)
      returnhash = {}
      records = self.filtered(options.merge(:activitygroup => 'contribution')).count('DISTINCT(activities.user_id)',:joins => :activity_object,:group => 'activity_objects.entrytype')
      records.map{|values| returnhash[values[0]] = values[1].to_i}
      return returnhash
    end
    
    def count_users_contributions_objects_by_activityentrytype(options={},forcecacheupdate=false)
      cache_key = self.get_cache_key(this_method,options)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do 
        returnhash = {}      

        edits = self.count_contributions_by_activityentrytype(options)
        objects = self.count_unique_activityobjects_by_activityentrytype(options)
        users = self.count_uniqueusers_contributing_by_activityentrytype(options)
      
      
        keys = edits.keys + objects.keys + users.keys 
        keys.uniq.each{|key| returnhash[ActivityObject::ENTRYTYPELABELS[key.to_i]] = {:contributions => 0, :users => 0, :objects => 0}}
      
        objects.each{|key,value| returnhash[ActivityObject::ENTRYTYPELABELS[key.to_i]][:objects] = value}
        edits.each{|key,value| returnhash[ActivityObject::ENTRYTYPELABELS[key.to_i]][:contributions] = value}
        users.each{|key,value| returnhash[ActivityObject::ENTRYTYPELABELS[key.to_i]][:users] = value}
        returnhash 
      end
    end 
    
        
    def activity_to_codes(activity)
      case activity
      when 'signup'
        return [Activity::SIGNUP]
      when 'login'
        return [Activity::LOGIN_PASSWORD,Activity::LOGIN_OPENID]
      when 'edit'
        return [Activity::INFORMATION_EDIT]
      when 'publish'
        return [Activity::INFORMATION_PUBLISH]
      when 'aaeresolve'
        return [Activity::AAE_RESOLVE]
      when 'aaereject'
        return [Activity::AAE_REJECT]
      when 'aaenoanswer'
        return [Activity::AAE_NOANSWER]
      when 'aaesubmission'
        return [Activity::AAE_SUBMISSION_WIDGET,Activity::AAE_SUBMISSION_PUBSITE]
      when 'aaesubmissionwidget'
        return [Activity::AAE_SUBMISSION_WIDGET]
      when 'aaesubmissionpubsite'
        return [Activity::AAE_SUBMISSION_PUBSITE]
      when 'joinedcommunity'
        return [Activity::COMMUNITY_JOIN,Activity::COMMUNITY_ACCEPT_INVITATION,Activity::COMMUNITY_ADDEDASMEMBER,Activity::COMMUNITY_ADDEDASLEADER]
      else
        return nil
      end
    end
    
    def activitygroup_to_types(activitygroup)
      case activitygroup
      when 'people'
        return [Activity::PEOPLE]
      when 'login'
        return [Activity::LOGIN]
      when 'information'
        return [Activity::INFORMATION]
      when 'contribution'
        return [Activity::INFORMATION,Activity::AAE]
      when 'aae'
        return [Activity::AAE]        
      when 'active'
        return [Activity::LOGIN,Activity::INFORMATION,Activity::AAE]
      when 'community'
        return [Activity::COMMUNITY]
      else
        return nil
      end
    end
    
    
    def code_to_activity(activitycode)
      case activitycode
      when Activity::SIGNUP
        return 'signup'
      when Activity::LOGIN_OPENID
      when Activity::LOGIN_PASSWORD
        return 'login'
      when Activity::INFORMATION_EDIT        
        return 'edit'
      when Activity::COMMUNITY_ACTIVITY
        return 'community'
      when Activity::COMMUNITY_JOIN
      when Activity::COMMUNITY_ACCEPT_INVITATION
      when Activity::COMMUNITY_ADDEDASMEMBER
      when Activity::COMMUNITY_ADDEDASLEADER
        return 'joinedcommunity'
      else
        return nil
      end
    end
    
    
    def log_activity(opts = {})
      # TODO: public activity
      if(opts[:activitycode] == COMMUNITY_INVITATIONRESCINDED or opts[:activitycode] == COMMUNITY_NOINTEREST)
        opts[:privacy] = Activity::PRIVATE
      else
        opts[:privacy] = Activity::PROTECTED
      end
      
      
      # creator check
      if(opts[:creator].nil?)
        opts[:creator] = User.systemuser
      end

      if(opts[:ipaddr].nil?)
        opts[:ipaddr] = AppConfig.configtable['request_ip_address']
      end

      # ActivityApplication lookups
      aa = opts.delete(:activity_application)
      if(aa.nil?) 
        # check for appname/trustroot - except for api auth, we should basically always hit this branch
        if(opts[:activitycode] == Activity::LOGIN_OPENID)
          trustroot = opts.delete(:trustroot)  # must have a trustroot for now
          opts[:activity_uri] = trustroot
          aa = ActivityApplication.finduri(trustroot)
          if(aa.nil?)
            opts[:privacy] = Activity::PRIVATE            
          end
        elsif(!opts[:appname].nil?)
          appname = opts.delete(:appname)
          if(appname == 'local')
            aa = ActivityApplication.local
          else
            aa = ActivityApplication.find_by_shortname(appname)
          end
        else #assume local
          aa = ActivityApplication.local
        end
      end


      if(aa.nil?)
        opts[:activity_application] = nil
      else
        opts[:activity_application] = aa
      end
      begin
        Activity.create(opts)
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.to_s =~ /duplicate/i
      end
      
    end
        
  end
  
  
  

end