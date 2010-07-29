# === COPYRIGHT:
# Copyright (c) 2005-2009 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'
class User < ActiveRecord::Base 
  extend ConditionExtensions
  include TaggingScopes
  serialize :additionaldata
  ordered_by :default => "last_name,first_name ASC"
  
  
  STATUS_CONTRIBUTOR = 0
  STATUS_REVIEW = 1
  STATUS_CONFIRMEMAIL = 2
  STATUS_REVIEWAGREEMENT = 3
  STATUS_PARTICIPANT = 4
  STATUS_RETIRED = 5
  STATUS_INVALIDEMAIL = 6
  STATUS_SIGNUP = 7
  STATUS_INVALIDEMAIL_FROM_SIGNUP = 8
  
  STATUS_OK = 100
  
  TIMECOLUMN_EMAIL_EVENT_AT = 1
  TIMECOLUMN_CONTRIBUTOR_AGREEMENT_AT = 2
  TIMECOLUMN_CREATED_AT = 3
  TIMECOLUMN_UPDATED_AT = 4
  TIMECOLUMN_LAST_LOGIN_AT = 5
   
  attr_protected :is_admin 
  
  has_many :sentinvitations, :class_name  => "Invitation"
  has_many :user_tokens, :dependent => :destroy
  has_many :emailtokens, :class_name  => "UserToken", :conditions => "user_tokens.tokentype = #{UserToken::EMAIL}"
  
  has_many :privacy_settings
  
  has_many :opie_approvals, :dependent => :destroy
  has_one :chat_account, :dependent => :destroy
  has_many :user_events, :order => 'created_at DESC', :dependent => :destroy
  has_many :activities, :order => 'created_at DESC', :dependent => :destroy
  
  has_many :notifications, :dependent => :destroy
  
  has_many :widget_events
  has_many :widgets
  has_many :responses
    
  belongs_to :position
  belongs_to :location
  belongs_to :county
  
  has_and_belongs_to_many :expertise_locations
  has_and_belongs_to_many :expertise_counties
  
  attr_reader :password_confirmation
  
  has_many :social_networks, :dependent => :destroy
  has_many :user_emails, :dependent => :destroy

  has_many :list_subscriptions, :dependent => :destroy
  
  has_many :communityconnections, :dependent => :destroy
  has_many :communities, :through => :communityconnections, :select => "communityconnections.connectiontype as connectiontype, communityconnections.sendnotifications as sendnotifications, communities.*", :order => "communities.name"
  
  has_many :list_subscriptions, :dependent => :destroy
  has_many :lists, :through => :list_subscriptions
  has_many :subscribedlists, :through => :list_subscriptions, :source => :list, :conditions => "list_subscriptions.optout = 0"
  has_many :nonsubscribedlists, :through => :list_subscriptions, :source => :list, :conditions => "list_subscriptions.optout = 1"
  
  
  has_many :list_owners, :dependent => :destroy
  has_many :listownerships, :through => :list_owners, :source => :list
  
  # TODO - this is a ridiculously insane number of has many associations - this needs to be fixed.
  has_many :communitiesofanyinterest, :through => :communityconnections, :source => :community, :conditions => "communityconnections.connectiontype != 'nointerest'", :order => "communities.name"
  has_many :communityopenjoins, :through => :communityconnections, :source => :community, :conditions => "(communityconnections.connectiontype = 'member' or communityconnections.connectiontype = 'leader') and communities.memberfilter = #{Community::OPEN}"
  has_many :communityinvitejoins, :through => :communityconnections, :source => :community, :conditions => "((communityconnections.connectiontype = 'member' and communities.memberfilter = #{Community::OPEN}) or communityconnections.connectiontype = 'leader')"
  has_many :connectjoins, :class_name => "Communityconnection", :conditions => "communityconnections.connectiontype = 'member' or communityconnections.connectiontype = 'leader'"
  has_many :connectinvitations, :class_name => "Communityconnection", :conditions => "communityconnections.connectiontype = 'invited'"
  has_many :connectjoinspluswantstojoin, :class_name  => "Communityconnection", :conditions => "communityconnections.connectiontype = 'wantstojoin' or communityconnections.connectiontype = 'member' or communityconnections.connectiontype = 'leader'"
  has_many :connectwantstojoins, :class_name   => "Communityconnection", :conditions => "communityconnections.connectiontype = 'wantstojoin'"  
  has_many :connectinterests, :class_name  => "Communityconnection", :conditions => "communityconnections.connectiontype = 'interest'"   
  has_many :connectionsofanyinterest, :class_name => "Communityconnection", :conditions => "communityconnections.connectiontype != 'nointerest'"  
  # TODO: end insane set of associations
  
  # tags and taggings
  has_many :ownedtaggings, :class_name => "Tagging"
  has_many :ownedtags, :through => :ownedtaggings, :source => :tag
  has_many :cached_tags, :as => :tagcacheable


  has_many :user_preferences
  has_many :assigned_questions, :class_name => "SubmittedQuestion", :foreign_key => "user_id"
  # TODO: this should be changed to something like .assigned_questions.open
  has_many :open_questions, :class_name => "SubmittedQuestion", :foreign_key => "user_id", :conditions => "status_state = #{SubmittedQuestion::STATUS_SUBMITTED} AND spam = false"
  has_many :resolved_questions, :class_name => "SubmittedQuestion", :foreign_key => "resolved_by"
  has_many :expertise_areas
  has_many :categories, :through => :expertise_areas
  has_many :expertise_events
  has_many :user_roles
  has_many :roles, :through => :user_roles
  has_many :assignment_widgets, :source => :widget, :through => :user_roles, :conditions => "role_id = #{Role.widget_auto_route.id}" 

  has_many :api_keys
  has_many :api_key_events, :through => :api_keys
  has_one  :directory_item_cache
  
  #has_many :listmemberships, :dependent => :destroy
  #has_many :listownerships, :dependent => :destroy
  #has_many :lists, :through => :listmemberships, :source => :list
  #has_many :ownedlists, :through => :listownerships, :source => :list
  
  # has_many :invitations
  
  has_many :learn_connections
  has_many :learn_sessions, :through => :learn_connections, :select => "learn_connections.connectiontype as connectiontype, learn_sessions.*"
  
  
  after_update :update_chataccount
  before_validation :convert_phonenumber
  before_save :check_status, :generate_feedkey
  before_create :set_encrypted_password
  before_update :set_encrypted_password
  
  validates_uniqueness_of :login, :on => :create
  
  # Starts with a letter, has letters, numbers, and underscores in the middle
  # and doesn't end with an underscore
  validates_format_of :login, :with => /^[a-zA-Z]+[a-zA-Z0-9]+$/, :on => :create

  validates_uniqueness_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/
  validates_length_of :email, :maximum=>96

  validates_confirmation_of :password, :message => 'has to be the same in both fields. Please type both passwords again.'
  validates_length_of :login, :within => 3..40
  validates_length_of :password, :within => 6..40
  validates_presence_of :first_name, :last_name, :email, :login, :password
  validates_presence_of :password_confirmation, :on => :create
  validates_length_of :phonenumber, :is => 10, :allow_blank => true
  
  
  # scopers
  named_scope :validusers, :conditions => {:retired => false,:vouched => true}
  named_scope :unconfirmedemail, :conditions => ["emailconfirmed = ? AND account_status != ?",false,User::STATUS_SIGNUP]
  named_scope :pendingsignups, :conditions => {:account_status => User::STATUS_SIGNUP}
  named_scope :active, :conditions => {:retired => false}
  
  named_scope :patternsearch, lambda {|searchterm|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' characters because it's causing a repitition search error
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').strip
    # in the format wordone wordtwo?
    words = sanitizedsearchterm.split(%r{\s*,\s*|\s+})
    if(words.length > 1)
      findvalues = { 
       :firstword => words[0],
       :secondword => words[1]
      }
      conditions = ["((first_name rlike :firstword AND last_name rlike :secondword) OR (first_name rlike :secondword AND last_name rlike :firstword))",findvalues]
    elsif(sanitizedsearchterm.to_i != 0)
      # special case of an id search - needed in admin/colleague searches
      conditions = ["id = #{sanitizedsearchterm.to_i}"]
    else
      findvalues = {
       :findlogin => sanitizedsearchterm,
       :findemail => sanitizedsearchterm,
       :findfirst => sanitizedsearchterm,
       :findlast => sanitizedsearchterm 
      }
      conditions = ["(email rlike :findemail OR login rlike :findlogin OR first_name rlike :findfirst OR last_name rlike :findlast)",findvalues]
    end
    {:conditions => conditions}
  }
  
  named_scope :filtered, lambda {|options| filterconditions(options)}  
  
  named_scope :missingtags,  :joins => "LEFT JOIN taggings ON (users.id = taggings.taggable_id AND taggings.taggable_type = 'User')", :conditions => 'taggings.id IS NULL'
  named_scope :missingnetworks, :joins => "LEFT JOIN social_networks ON users.id = social_networks.user_id",  :conditions => 'social_networks.id IS NULL'
    
  named_scope :date_users, lambda { |date1, date2| { :conditions => (date1 && date2) ?   [ " TRIM(DATE(users.created_at)) between ? and ?", date1, date2] : "true" } }
  
  named_scope :escalators_by_category, lambda {|category|
   {:joins => [:roles, :categories], :conditions => ["roles.name = '#{Role::ESCALATION}' AND categories.name = '#{category.name}'"], :order => "last_name,first_name ASC" }
  }
  
  named_scope :auto_routers, {:include => :roles, :conditions => "roles.name = '#{Role::AUTO_ROUTE}' AND users.aae_responder = true", :order => "last_name,first_name ASC"}
  
  named_scope :experts_by_location_only, :joins => :user_preferences, :conditions => "user_preferences.name = '#{UserPreference::AAE_LOCATION_ONLY}'", :order => "last_name,first_name ASC"
  named_scope :experts_by_county_only, :joins => :user_preferences, :conditions => "user_preferences.name = '#{UserPreference::AAE_COUNTY_ONLY}'", :order => "last_name,first_name ASC"
  
  named_scope :question_wranglers, :joins => :communityconnections, :conditions => "communityconnections.community_id = #{Community::QUESTION_WRANGLERS_COMMUNITY_ID} and (communityconnections.connectiontype = 'member' or communityconnections.connectiontype = 'leader')", :order => "last_name,first_name ASC"
   
  named_scope :experts_by_county, lambda {|county| {:joins => "join expertise_counties_users as ecu on ecu.user_id = users.id", :conditions => "ecu.expertise_county_id = #{county.id}", :order => "last_name,first_name ASC"}}
  named_scope :experts_by_location, lambda {|location| {:joins => "join expertise_locations_users as elu on elu.user_id = users.id", :conditions => "elu.expertise_location_id = #{location.id}", :order => "last_name,first_name ASC"}}
  named_scope :routers_outside_location, lambda {
   location_routers = UserPreference.find(:all, :conditions => "name = '#{UserPreference::AAE_LOCATION_ONLY}' OR name = '#{UserPreference::AAE_COUNTY_ONLY}'").collect{|up| up.user_id}.uniq.join(',')
   {:conditions => "users.id NOT IN (#{location_routers}) AND users.aae_responder = true", :order => "last_name,first_name ASC"}
  
  }
  
  named_scope :experts_by_category, lambda { |category_id| 
   {:include => :expertise_areas, :conditions => "expertise_areas.category_id = #{category_id}", :order => "last_name,first_name ASC"}
  }
  
  named_scope :question_responders, :conditions => {:aae_responder => true}
  
  
  # all experts who have a particular location marked either in their aae prefs OR in their people profile
  # orignally used for aae expert search where we want to see all those experts from a location 
  # whether or not they marked their aae geographic prefs
  named_scope :experts_from_aae_or_people_location, lambda {|location_fips|
    location = Location.find_by_fipsid(location_fips)
    aae_location = ExpertiseLocation.find_by_fipsid(location_fips)
    aae_location_user_ids = aae_location.users.collect{|eu| eu.id}.join(',')
    if aae_location_user_ids.length > 0
     {:conditions => "users.id IN (#{aae_location_user_ids}) OR users.location_id = #{location.id}", :group => "users.id"}
    else
     {:conditions => " users.location_id = #{location.id}", :group => "users.id"}
    end
  }
  
  # override login write
  def login=(loginstring)
   write_attribute(:login, loginstring.mb_chars.downcase)
  end
  
  # override email write
  def email=(emailstring)
   write_attribute(:email, emailstring.mb_chars.downcase)
  end
  
  def openid_url(claimed=false)
   peoplecontroller = 'people'
   location = AppConfig.configtable['app_location']
   
   if(AppConfig.configtable['openid_url_prefix'][location].nil? or AppConfig.configtable['openid_url_prefix'][location] == 'request_url')
    openid_url_prefix = "#{AppConfig.configtable['url_options']['protocol']}#{AppConfig.configtable['url_options']['host']}#{AppConfig.url_port_string}/#{peoplecontroller}"
   elsif(AppConfig.configtable['openid_url_prefix'][location].is_a?(Hash))
    if(claimed)       
      openid_url_prefix = AppConfig.configtable['openid_url_prefix'][location]['claimed']
    else
      openid_url_prefix = AppConfig.configtable['openid_url_prefix'][location]['local']
    end
   else
    openid_url_prefix = AppConfig.configtable['openid_url_prefix'][location]
   end
   
   return "#{openid_url_prefix}/#{self.login.downcase}"
  end  
  
  def primary_institution
   # communityconnections is automatically included with the :communities association
   return self.communities.institutions.find(:first, :conditions => "communityconnections.connectioncode = #{Communityconnection::PRIMARY}")
  end
  
  def primary_institution_name(niltext = 'not specified')
   if(institution = self.primary_institution)
    return institution.name
   else
    return niltext
   end
  end
  
  # returns a hash of communities organized by connectiontypes
  def communities_by_connectiontype
    returnhash = {}
    mycommunities = self.communities
    returnhash['joined'] = mycommunities.reject{|community| (community.connectiontype != 'member' and community.connectiontype != 'leader')}
    returnhash['wantstojoin'] = mycommunities.reject{|community| (community.connectiontype != 'wantstojoin')}
    returnhash['member'] = mycommunities.reject{|community| (community.connectiontype != 'member')}
    returnhash['leader'] = mycommunities.reject{|community| (community.connectiontype != 'leader')}
    returnhash['interest'] = mycommunities.reject{|community| (community.connectiontype != 'interest')}
    returnhash['nointerest'] = mycommunities.reject{|community| (community.connectiontype != 'nointerest')}
    returnhash['invited'] = mycommunities.reject{|community| (community.connectiontype != 'invited')}
    returnhash['all'] = mycommunities
    returnhash
  end

  
  def update_public_attributes
    self.public_attributes(true)
  end
  
  # returns a hash of public attributes
  def public_attributes(forcecacheupdate = false)
    directory_item_cache = self.directory_item_cache
    if(!forcecacheupdate and !directory_item_cache.nil?)  
      if(directory_item_cache.public_attributes.blank?)
        return nil
      else
        return directory_item_cache.public_attributes
      end
    end
    
    returnhash = {}
    publicsettings = self.privacy_settings.showpublicly.all
    socialnetworks = self.social_networks.showpublicly.all
   
    if(publicsettings.empty? and socialnetworks.empty?)
      # cache the blank value
      if(directory_item_cache)
        directory_item_cache.update_attributes({:public_attributes => nil})      
      else
        DirectoryItemCache.create({:user => self, :public_attributes => nil})      
      end
      return nil
    else
      returnhash.merge!({:fullname => self.fullname, :last_name => self.last_name, :first_name => self.first_name})
    end
   
   if(!publicsettings.empty?)
    publicsettings.each do |setting|
      case setting.item
      when 'email'
       returnhash.merge!({:email => self.email})
      when 'phone'
       returnhash.merge!({:phone => self.phonenumber.nil? ? '' : self.phonenumber})
      when 'title'
       returnhash.merge!({:title => self.title.nil? ? '' : self.title})
      when 'position'
       returnhash.merge!({:position => self.position.nil? ? '' : self.position.name})
      when 'institution'
       returnhash.merge!({:institution => self.primary_institution_name('')})
      when 'location'
       returnhash.merge!({:location => (self.location.nil? ? '' : self.location.name)})
      when 'county'
       returnhash.merge!({:county => (self.county.nil? ? '' : self.county.name)})
      when 'interests'
       returnhash.merge!({:interests => self.tag_displaylist_by_ownerid_and_kind(self.id,Tagging::ALL,true)})
      end
    end  
   end
   
   if(!socialnetworks.empty?)
    returnnetworks = []
    socialnetworks.each do |sn|
      returnnetworks << {:accountid => sn.accountid, :network => sn.network, :displayname => sn.displayname, :accounturl => sn.accounturl}
    end
    returnhash.merge!({:socialnetworks => returnnetworks})
   end
   
   # cache it
   if(directory_item_cache)
     directory_item_cache.update_attributes({:public_attributes => returnhash})      
   else
     DirectoryItemCache.create({:user => self, :public_attributes => returnhash})
   end 
   return returnhash
  end
  
  def update_chataccount
   # remove chat account if retired
   if (self.retired? or !self.vouched? or self.account_status == User::STATUS_SIGNUP)
    if(!self.chat_account.nil?)
      self.chat_account.destroy
    end
   else
    if(self.chat_account.nil?)
      self.create_chat_account
    else
      self.chat_account.save
    end
   end
  end
   
  def fullname 
   return "#{self.first_name} #{self.last_name}"
  end
  
  def retire
    self.retired = true
    self.retired_at = Time.now()
    if(self.save)
     self.clear_all_list_and_community_connections
     return true
    else
     return false
    end
  end
  
  # returns a hash of aae filter prefs
  def aae_filter_prefs
   returnhash = {}
   self.user_preferences.each do |preference|
    case preference.name
    when UserPreference::AAE_FILTER_CATEGORY
      if preference.setting == Category::UNASSIGNED
       category = Category::UNASSIGNED
      else  
       category = Category.find_by_id(preference.setting)
      end
      returnhash[:category] = category
    when UserPreference::AAE_FILTER_LOCATION
      returnhash[:location] = Location.find_by_fipsid(preference.setting)      
    when UserPreference::AAE_FILTER_COUNTY
      returnhash[:county] = County.find_by_fipsid(preference.setting)
    when UserPreference::AAE_FILTER_SOURCE
      returnhash[:source] = preference.setting 
    end 
   end
   return returnhash
  end
  
  def aae_auto_route_role
    if auto_route_role = self.user_roles.find_by_role_id(Role.find_by_name(Role::AUTO_ROUTE).id)
      return auto_route_role
    else
      return nil
    end
  end
  
  def aae_escalation_role
    if escalation_role = self.user_roles.find_by_role_id(Role.find_by_name(Role::ESCALATION).id)  
      return escalation_role
    else
      return nil
    end
  end
  
   
  def clear_all_list_and_community_connections
   # WARNING WARNING DANGER WILL ROBINSON
   # log for recovery if we need to...
   mylists = {}
   self.lists.map{|list| mylists[list.name] = list.id}
   mylistownerships = {}
   self.listownerships.map{|list| mylistownerships[list.name] = list.id}
   mycommunities = {}
   self.communities.map{|community| mycommunities[community.name] = community.id}
        
   # drop all ListSubscriptions
   droppedsubscriptionscount = ListSubscription.drop_subscriptions(self)
   if(droppedsubscriptionscount > 0)
    AdminEvent.log_data_event(AdminEvent::REMOVE_SUBSCRIPTION, {:userlogin => self.login, :listcount => droppedsubscriptionscount, :lists => mylists})
   end
   
   # drop all ListOwnerships
   droppedownershipscount = ListOwner.drop_ownerships(self)
   if(droppedownershipscount > 0)
    AdminEvent.log_data_event(AdminEvent::REMOVE_OWNERSHIP, {:userlogin => self.login, :listcount => droppedownershipscount, :lists => mylistownerships})
   end
   
   # drop all CommunityConnections
   droppedcommunitiescount = Communityconnection.drop_connections(self)
   if(droppedcommunitiescount > 0)
    AdminEvent.log_data_event(AdminEvent::REMOVE_COMMUNITY_CONNECTION, {:userlogin => self.login, :communitycount => droppedcommunitiescount, :communities => mycommunities})
   end
   
   return true
   
  end
  
  def enable
    self.retired = false
    self.retired_at = nil
    if(self.save)
     self.updatelistemails
     return true
    else
     return false
    end
  end
  
  def vouch(voucher)
   self.vouched = true
   self.vouched_by = voucher.id
   self.vouched_at = Time.now.utc
   if(self.save)
    self.updatelistemails
    if(!self.additionaldata.nil? and !self.additionaldata[:signup_institution_id].nil?)
      self.change_profile_community(Community.find(self.additionaldata[:signup_institution_id]))
    end
    return true
   else
    return false
   end
  end
  
  def set_new_password(token,password,password_confirmation)
   if(self.account_status == User::STATUS_SIGNUP and !token.tokendata.nil? and token.tokendata[:signuptoken_id])
    if(signuptoken = UserToken.find(token.tokendata[:signuptoken_id]))
      didsignup = self.confirm_signup(signuptoken,false)
    else
      didsignup = false
    end
   else
    didsignup = false
    now = Time.now.utc     
    if(!self.emailconfirmed?)
      self.emailconfirmed = true
      self.email_event_at = now
    end
   end
   
   self.password = password
   self.password_confirmation = password_confirmation
   if(self.save)      
    self.user_tokens.resetpassword.delete_all
    self.checklistemails
    if(didsignup)
      self.user_tokens.signups.delete_all
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "signup")
      Activity.log_activity(:user => self, :creator => self, :activitycode => Activity::SIGNUP, :appname => 'local')      
    end
    UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "set new password") 
   end
  end
  
  # very similiar to confirm_signup, only used for bypassing email confirmation and vouching
  # for those that have a training_invitation 
  def training_signup?
   # is there a training_invitation with my email in it?
   # TODO: deal with expiration at some point
   training_invitation = TrainingInvitation.find_by_email(self.email)     
   return false if(training_invitation.nil?)
   
   # TODO: should I check if the training_invitation has already been filled,  not sure how on
   # earth that could happen, but knowing how this goes, I'm sure it would
   
   now = Time.now.utc
   self.vouched = true 
   self.vouched_by = training_invitation.created_by
   self.vouched_at = now
   
   # is there an unaccepted normal invitation with this email address in it? - then let's call it an accepted invitation
   invitation = Invitation.find(:first, :conditions => ["email = '#{self.email}' and status = #{Invitation::PENDING}"])
   if(!invitation.nil?)
    invitation.accept(self,now)
   end
   
   # email settings
   self.emailconfirmed = true
   self.email_event_at = now
   self.account_status = User::STATUS_OK
   
   if(self.save)
    UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "training signup")
    Activity.log_activity(:user => self, :creator => self, :activitycode => Activity::SIGNUP, :appname => 'local')      
    self.checklistemails
    self.user_tokens.signups.delete_all
    training_invitation.update_attributes({:user_id => self.id, :completed_at => now})
    return true
   else
    return false
   end  
  end
  
  
  def confirm_signup(token,dosave=true)
   now = Time.now.utc
   
   if(self.has_whitelisted_email?)
    self.vouched = true 
    self.vouched_by = self.id
    self.vouched_at = now
   end
   
   # was this person invited? - even if can self-vouch, this will overwrite vouched_by
   if(!token.tokendata.nil? and token.tokendata[:invitation_id])
    invitation = Invitation.find(token.tokendata[:invitation_id])
    if(!invitation.nil?)
      if(self.has_whitelisted_email? or (invitation.email.downcase == self.email.downcase))
       invitation.accept(self,now)
       self.vouched = true 
       self.vouched_by = invitation.user.id
       self.vouched_at = now
      else
       # TODO:   what we really should do here is send an email to the person that made the invitation
       # and ask them to vouch for the person with the different email that used the right invitation code
       # but a different, non-whitelisted email.
       invitation.status = Invitation::INVALID_DIFFERENTEMAIL
       invitation.additionaldata = {:invalid_reason => 'invitation email does not match signup email', :signup_email => self.email}
       invitation.save
      end
    end
   end
   
   # is there an unaccepted invitation with this email address in it? - then let's call it an accepted invitation
   invitation = Invitation.find(:first, :conditions => ["email = '#{self.email}' and status = #{Invitation::PENDING}"])
   if(!invitation.nil?)
    invitation.accept(self,now)
    self.vouched = true 
    self.vouched_by = invitation.user.id
    self.vouched_at = now
   end  
  
   # email settings
   self.emailconfirmed = true
   self.email_event_at = now
   self.account_status = User::STATUS_OK
   
   if(dosave)
    if(self.save)
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "signup")
      Activity.log_activity(:user => self, :creator => self, :activitycode => Activity::SIGNUP, :appname => 'local')      
      self.checklistemails
      self.user_tokens.signups.delete_all
      return true
    else
      return false
    end
   else
    return true
   end
  end
  
  def invalidemail
   if(self.account_status == STATUS_SIGNUP)
    self.update_attribute(:account_status, STATUS_INVALIDEMAIL_FROM_SIGNUP)
   else
    self.update_attribute(:account_status, STATUS_INVALIDEMAIL)
   end
  end
   
  def checkpass(clear_password_string)
   if(clear_password_string.nil? or clear_password_string.empty?)
    return false
   end
   encrypted_password = self.encrypt_password_string(clear_password_string)
   if(encrypted_password == self.password)
    
    return true
   else
    return false
   end
  end 
  
  def recent_public_activity(limit=10)
   self.activities.displayactivity.find(:all, :order => 'created_at DESC', :limit => limit)
  end
  
  def check_email_review?
   return (!(self.has_whitelisted_email?))
  end
  
  def has_whitelisted_email?
   if (self.email =~ /edu$|gov$|extension\.org$|nasulgc\.org$|fs.fed.us$/i)
    return true
   else
    return false
   end
  end
   
  def checklistemails(oldmail = nil)
   # this will handle all list subscriptions, not just those that are associated currently
   if(!oldmail.nil?)
    listsubs = ListSubscription.find(:all, :conditions => ["email = ?",oldemail])
   else
    # do this instead to force association with self
    listsubs = ListSubscription.find(:all, :conditions => ["email = ?",self.email])
   end
   
   if(!listsubs.blank?)
    listsubs.each do |listsub|
      listsub.update_attributes({:email => self.email, :user_id => self.id, :emailconfirmed => self.emailconfirmed})
      AdminEvent.log_data_event(AdminEvent::UPDATE_SUBSCRIPTION, {:listname => listsub.list.name, :userlogin => self.login, :email => self.email, :emailconfirmed => self.emailconfirmed })
    end
   else
    # add to announce lists
    self.checkannouncelists
   end
  end
  
  def updatelistemails
   if(!self.lists.blank?)
    self.lists.each do |list|
      list.add_or_update_subscription(self)
    end
   else
    # add to announce lists
    self.checkannouncelists
   end
  end
  
  
  def checkannouncelists
   logger.debug "=================================== Inside checkannouncelists: #{self.id} #{self.login}"
   announce = List.find_announce_list
   
   if(!announce.nil?)
    announce.add_or_update_subscription(self)
   end
   
   return true
  end
  
  def ineligible_for_listsubscription?
   return (self.retired? or !self.vouched?)
  end

  def modify_or_create_connection_to_community(community,options = {})
   operation = options[:operation]
   connectiontype = options[:connectiontype]
   
   if(operation.nil? or connectiontype.nil?)
    return false
   end
   
   connector = options[:connector].nil? ? self : options[:connector]
   connectioncode = options[:connectioncode].nil? ? 0 : options[:connectioncode]
   connection = Communityconnection.find_by_user_id_and_community_id(self.id,community.id)

   case operation
   when 'add'
    if(community.is_institution?)
      # do I have a primary institution connection?  if not, make this primary
      if(community.is_institution? and self.primary_institution.nil?)
       connectioncode = Communityconnection::PRIMARY
      end
      # is this a leadership connection?  if so, add them to the institutional teams community
      if(connectiontype == 'leader')
       Community.find(Community::INSTITUTIONAL_TEAMS_COMMUNITY_ID).add_user_to_membership(self,User.systemuser)
      end
    end
      
    if(connection.nil?)
      Communityconnection.create(:user => self, :community => community, :connectiontype => connectiontype, :sendnotifications => (connectiontype == 'leader'), :connector => connector, :connectioncode => connectioncode)
    else
      attributes_to_update = {:connectiontype => connectiontype, :connector => connector, :connectioncode => connectioncode}
      if(connectiontype == 'leader')
       # force notifications to be on
       attributes_to_update.merge!({:sendnotifications => true})
      end
      connection.update_attributes(attributes_to_update)
    end
    return true
   when 'remove'
    if(!connection.nil?)
      if(connector != self)
       if(connectiontype == 'leader')
        # is this an institution - remove from institutional teams community
        if(community.is_institution?)
          Community.find(Community::INSTITUTIONAL_TEAMS_COMMUNITY_ID).remove_user_from_membership(self,User.systemuser)
        end
        # make them a member
        connection.update_attributes({:connectiontype => 'member', :connector => connector, :connectioncode => connectioncode})
       else  # TODO:   deal with interest change/wants to join removal
        connection.destroy
       end
      else
       if(community.is_institution?)
        Community.find(Community::INSTITUTIONAL_TEAMS_COMMUNITY_ID).remove_user_from_membership(self,User.systemuser)
       end
       connection.destroy
      end
    end
    return true
   else
    return false
   end  
  end
  
  def modify_or_create_communityconnection(community,options)
   connector = options[:connector].nil? ? self : options[:connector]
   success = modify_or_create_connection_to_community(community,options)
   if(success)
    if(options[:activitycode])
      Activity.log_activity(:user => self,:creator => connector, :community => community, :activitycode => options[:activitycode], :appname => 'local')
    end
    
    if(options[:notificationcode] and options[:notificationcode] != Notification::NONE)
      Notification.create(:notifytype => options[:notificationcode], :user => self, :creator => connector, :community => community)
      # FIXME: user events really shouldn't be based on notificationcodes, but such is life
      if(connector != self)
       UserEvent.log_event(:etype => UserEvent::COMMUNITY,:user => connector,:description => Notification.userevent(options[:notificationcode],self,community))
       UserEvent.log_event(:etype => UserEvent::COMMUNITY,:user => self,:description => Notification.showuserevent(options[:notificationcode],self,connector,community))
      else
       UserEvent.log_event(:etype => UserEvent::COMMUNITY,:user => self,:description => Notification.userevent(options[:notificationcode],self,community))
      end
    end
    
    if(!options[:no_list_update])
      operation = options[:operation]
      connectiontype = options[:connectiontype]
      community.update_lists_with_user(self,operation,connectiontype)
    end
   end
  end
  
  def join_community_as_leader(community)
   # only called for user community creation - so no activity/no notification necessary
   self.modify_or_create_communityconnection(community,{:operation => 'add', :connectiontype => 'leader'})
  end
  
  def join_community(community,notify=true)
   activitycode = Activity::COMMUNITY_JOIN
   notificationcode = notify ? Notification.translate_connection_to_code('join') : Notification::NONE
   self.modify_or_create_communityconnection(community,{:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'add', :connectiontype => 'member'})
  end
  
  def wantstojoin_community(community,notify=true)
   activitycode = Activity::COMMUNITY_WANTSTOJOIN
   notificationcode = notify ? Notification.translate_connection_to_code('wantstojoin') : Notification::NONE
   self.modify_or_create_communityconnection(community,{:activitycode => activitycode, :notificationcode => notificationcode, :operation => 'add', :connectiontype => 'wantstojoin'})
  end
  
  def change_profile_community(newcommunity,oldcommunity = nil)
   if(newcommunity.nil?)
    return false
   end
   
   if(!oldcommunity.nil?)
    if(newcommunity == oldcommunity)
      return true
    end
    self.leave_community(oldcommunity)
   end
   
   if(newcommunity.memberfilter == Community::OPEN)
    self.join_community(newcommunity)
   elsif(newcommunity.memberfilter == Community::MODERATED)
    self.wantstojoin_community(newcommunity)
   end
   
   return true
  end
  
  def interest_community(community,notify=true)
   activitycode = Activity::COMMUNITY_INTEREST
   notificationcode = notify ? Notification.translate_connection_to_code('interest') : Notification::NONE
   self.modify_or_create_communityconnection(community,{:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'add', :connectiontype => 'interest'})
  end
  
  def nointerest_community(community,notify=true)
   activitycode = Activity::COMMUNITY_NOINTEREST
   notificationcode = notify ? Notification.translate_connection_to_code('nointerest') : Notification::NONE
   self.modify_or_create_communityconnection(community,{:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'add', :connectiontype => 'nointerest'})
  end
  
  def leave_community(community,notify=true)
   if(self.connection_with_community(community) == 'wantstojoin')
    activitycode = Activity::COMMUNITY_NOWANTSTOJOIN        
    notificationcode = notify ? Notification.translate_connection_to_code('nowantstojoin') : Notification::NONE
   elsif(self.connection_with_community(community) == 'interest')
    activitycode = Activity::COMMUNITY_NOINTEREST
    notificationcode = notify ? Notification.translate_connection_to_code('nointerest') : Notification::NONE
   else
    activitycode = Activity::COMMUNITY_LEFT
    notificationcode = notify ? Notification.translate_connection_to_code('leave') : Notification::NONE
   end
   self.modify_or_create_communityconnection(community,{:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'remove', :connectiontype => 'all'})
  end
  
  def accept_community_invitation(community,notify=true)
   connection = Communityconnection.find_by_user_id_and_community_id(self.id,community.id)
   if(!connection.nil?)
    if(connection.connectioncode == Communityconnection::INVITEDLEADER)
      connectiontype = 'leader'
    elsif(connection.connectioncode == Communityconnection::INVITEDMEMBER)
      connectiontype = 'member'
    else
      connectiontype = 'member'
    end
    activitycode = Activity::COMMUNITY_ACCEPT_INVITATION     
    notificationcode = notify ? Notification.translate_connection_to_code('accept') : Notification::NONE
    self.modify_or_create_communityconnection(community,{:activitycode => activitycode, :notificationcode => notificationcode,:operation => 'add', :connectiontype => connectiontype})
   else
    return false
   end
  end
  
  def decline_community_invitation(community,notify=true)
   activitycode = Activity::COMMUNITY_DECLINE_INVITATION
   notificationcode = notify ? Notification.translate_connection_to_code('decline') : Notification::NONE  
   self.modify_or_create_communityconnection(community,{:activitycode => activitycode, :notificationcode => notificationcode,:operation => 'remove', :connectiontype => 'all'})
  end

  def is_community_leader?(community)
   return (self.connection_with_community(community) == 'leader')
  end
  
  def connection_with_community(community)
   connection = Communityconnection.find_by_user_id_and_community_id(self.id,community.id)
   if(connection.nil?)
    return 'none'
   elsif(connection.connectiontype == 'invited')
    if(connection.connectioncode == Communityconnection::INVITEDLEADER)
      return 'invitedleader'
    elsif(connection.connectioncode == Communityconnection::INVITEDMEMBER)
      return 'invitedmember'
    else
      return 'invited'
    end 
   else
    return connection.connectiontype
   end
  end
  
  def connection_display(community)
   connection = self.connection_with_community(community)
   case connection
   when 'none'
    return 'No Connection'
   when 'invitedleader'
    return (community.is_institution? ? 'Institutional Team' : 'Invited (Institutional Team)')
   when 'invitedmember'
    return 'Invited (Member)'
   when 'wantstojoin'
    return 'Wants to Join'
   when 'nointerest'
    return 'Not Interested'
   when 'leader'
    return (community.is_institution? ? 'Institutional Team Leader' : 'Leader')
   else
    return connection.capitalize
   end
  end
  
  def community_connect_date(community,whichdate)
   connection = Communityconnection.find_by_user_id_and_community_id(self.id,community.id)
   if(connection.nil?)
    return nil
   else
    if(whichdate == "updated")
      return connection.updated_at
    else
      return connection.created_at
    end     
   end
  end
  
  def get_invited_by(community)
   connection = Communityconnection.find_by_user_id_and_community_id(self.id,community.id)
   if(connection.nil?)
    return nil
   elsif(connection.connectiontype != 'invited')
    return nil
   else
    return connection.connector
   end
  end
  
  def peer_top_tags(association,limit=25)
   # convert association to symbol
   symbol = association.to_sym
   if(association = self.class.reflect_on_association(symbol))
    if(self.attribute_present?(association.primary_key_name))
      conditions = Array.new
      conditions << "`#{self.class.table_name}`.#{association.primary_key_name} = #{self.attributes[association.primary_key_name]}"
      return self.class.top_tags_by_conditions(conditions,limit)
    else
      return []
    end
   else
    return []
   end
  end
  
  def tag_myself_with(taglist)
   self.replace_tags(taglist,self.id,Tagging::USER)
  end
  
  def modify_user_emails(otheruseremails)
   if(otheruseremails.nil?)
    return user_emails.delete_all
   end
   
   if(!otheruseremails['new'].nil? and !otheruseremails['new'].empty?)
    otheruseremails['new'].each do |attributes|
      user_emails.build(attributes)
    end
   end
   
   if(!otheruseremails['existing'].nil? and !otheruseremails['existing'].empty?)
    existingnetworks = otheruseremails['existing']
    user_emails.reject(&:new_record?).each do |user_email|
      attributes = existingnetworks[user_email.id.to_s]
      if attributes
       user_email.attributes = attributes
      else
       user_emails.delete(user_email)
      end
    end
   end

   user_emails.each do |user_email|
    begin
      user_email.save()
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.to_s =~ /duplicate/i
    end
   end
   
  end
  
  def modify_social_networks(socialnetworks)
   if(socialnetworks.nil?)
    return social_networks.delete_all
   end
   
   if(!socialnetworks['new'].nil? and !socialnetworks['new'].empty?)
    socialnetworks['new'].each do |attributes|
      social_networks.build(attributes)
    end
   end
   
   if(!socialnetworks['existing'].nil? and !socialnetworks['existing'].empty?)
    existingnetworks = socialnetworks['existing']
    social_networks.reject(&:new_record?).each do |social_network|
      attributes = existingnetworks[social_network.id.to_s]
      if attributes
       social_network.attributes = attributes
      else
       social_networks.delete(social_network)
      end
    end
   end

   social_networks.each do |social_network|
    begin
      social_network.save()
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.to_s =~ /duplicate/i
    end
   end
   
  end
  
  def is_relevant_community?(community)
   return community_relevance(community) > 0
  end

  def community_relevance(community)
   communitytags = community.shared_tag_list('all')
   if(communitytags.empty?)
    return(0)
   end
   
   
   matching_tags = communitytags & self.tags
   if(matching_tags.empty?)
    return(0)
   end
   
   
   communityusercount = community.validusers.count
   min_of_tag_counts = [matching_tags.size,self.tags.count].min
   weighted_frequency = communitytags.sum{|t| (matching_tags.include?(t)) ? (t.weightedfrequency.to_f / communityusercount) : 0}
   relevancy_score = weighted_frequency / min_of_tag_counts
   
   return relevancy_score
   
  end
  
  # returns an array of the communities and their relevancy scores
  def get_relevant_communities(options = {})
   returnhash = {}
   return returnhash if (self.tag_list.blank?)
   
   skipmine = options[:filtermine].nil? ? true : options[:filtermine]
   skipsystem = options[:filtersystem].nil? ? true : options[:filtersystem]
   
   # step one - get the communities - and tag frequencies
   all_matching_communities_plus_tags = Community.tagged_with_any(self.tag_list,{:getfrequency => true,:minweight => 2})
   return [] if all_matching_communities_plus_tags.length == 0

   matching_community_list = all_matching_communities_plus_tags.uniq
   
   if(skipmine)
    matching_community_list = matching_community_list - self.communities
   end
   
   return [] if matching_community_list.length == 0
   
   # step four, get the sums and counts

   
   matching_community_list.uniq.each do |community|
    communityusercount = community.validusers.count
    matching_tags_count = all_matching_communities_plus_tags.sum{|c| (community == c) ? 1 : 0}
    min_of_tag_counts = [matching_tags_count,self.tags.count].min
    weighted_frequency = all_matching_communities_plus_tags.sum{|c| (community == c) ? (c.weightedfrequency.to_f/communityusercount) : 0}
   
    returnhash[community] = {:usercount => communityusercount,
                      :matching_tags_count => matching_tags_count,
                      :min_of_tag_counts => min_of_tag_counts,
                      :weighted_frequency => weighted_frequency,
                      :relevancy_score => weighted_frequency / min_of_tag_counts }
   end

   return returnhash
  end
  
  def relevant_community_scores(options = {})
   returnhash = {}
   return returnhash if (self.tag_list.blank?)
   valueshash = get_relevant_communities(options)
   
   # return only relevancies for now
   valueshash.each do |community,metrics|
    returnhash[community] = metrics[:relevancy_score]
   end
   
   # TODO: sort and limit, return DESC by default
   returnhash.sort{|a,b| b[1] <=> a[1]}
  
  end
  
  def set_primary_institution(community)
   if(self.primary_institution == community)
    return true
   end
   
   # clear current primary institution
   if(!self.primary_institution.nil?)
    currentprimary = self.communityconnections.find(:first, :conditions => "community_id = #{self.primary_institution.id}")
    if(!currentprimary.nil?)
      currentprimary.update_attribute(:connectioncode,nil)
    end
   end
      
   # set this one to primary
   newprimary = self.communityconnections.find(:first, :conditions => "community_id = #{community.id}")
   if(!newprimary.nil?)
    newprimary.update_attribute(:connectioncode,Communityconnection::PRIMARY)
   end
   return true
  end
  
  def clear_primary_institution(community)
   if(self.primary_institution != community)
    return true
   end
   
   # set this one to primary
   clearprimary = self.communityconnections.find(:first, :conditions => "community_id = #{community.id}")
   if(!clearprimary.nil?)
    clearprimary.update_attribute(:connectioncode,nil)
   end
   # TODO: this might should find another institution that the person belongs to and force it primary - maybe
   # at the least, it's a known issue.
  end
  
  def update_notification_for_community(community,notification)
   connection = self.communityconnections.find(:first, :conditions => "community_id = #{community.id}")
   if(!connection.nil?)
    connection.update_attribute(:sendnotifications,notification)
   end
  end
  
  def update_connection_to_learn_session(learn_session,connectiontype,connected=true)
    connection = self.learn_connections.find(:first, :conditions => "connectiontype = #{connectiontype} and learn_session_id = #{learn_session.id}")
    if(!connection.nil?)
      if(!connected)
        connection.destroy
      end
    elsif(connected == true)
      LearnConnection.create(:learn_session_id => learn_session.id, :user_id => self.id, :connectiontype => connectiontype, :email => self.email)
    end
  end
        
    
 
  def is_sudoer?
   return AppConfig.configtable['sudoers'][self.login.downcase]
  end
 
  def get_subscription_to_list(list)
   if(list.nil?)
    nil
   else
    ListSubscription.find_by_user_id_and_list_id(self.id,list.id)
   end
  end
  
  def get_ownership_for_list(list)
   if(list.nil?)
    nil
   else
    ListOwner.find_by_user_id_and_list_id(self.id,list.id)
   end
  end
  
  def update_notification_for_list(list,notification)
   listsub = self.get_subscription_to_list(list)    
   if(!listsub.nil?)
    # update my announcements flag for the announce list
    if(list.is_announce_list?)
      self.update_attribute(:announcements,notification)
    end
    listsub.update_attribute(:optout,!notification)
   end
   return listsub
  end
  
  def update_moderation_for_list(list,moderation)
   listownership = self.get_ownership_for_list(list)    
   if(!listownership.nil?)
    listownership.update_attribute(:moderator,moderation)
   end
   return listownership
  end
  
  def fix_email(newemailaddress,adminuser)
   now = Time.now.utc
   
   old_email_address = self.email
   if(self.update_attributes(:email => newemailaddress))
    AdminEvent.log_event(adminuser, AdminEvent::CHANGE_EMAIL,{:extensionid => self.login, :oldemail => old_email_address, :newemail => self.email})
    UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "email address changed by #{adminuser.login}")
   else
    return false
   end
   
   if(self.account_status == STATUS_INVALIDEMAIL_FROM_SIGNUP)
    self.resend_signup_confirmation({:fromfixemail => true, :oldemail => old_email_address, :newemail => self.email})
    return true
   end
   
   if(self.account_status != STATUS_CONFIRMEMAIL or self.emailconfirmed != false)
    self.update_attributes(:account_status => STATUS_CONFIRMEMAIL,:email_event_at => now, :emailconfirmed => false)
    self.updatelistemails
   end
   token = UserToken.create(:user=>self,:tokentype=>UserToken::EMAIL, :tokendata => {:email => self.email, :oldemail => old_email_address})
   Notification.create(:notifytype => Notification::CONFIRM_EMAIL_CHANGE, :user => self, :send_on_create => true, :additionaldata => {:token_id => token.id})   
   return true
  end
  
  def resend_signup_confirmation(options={})
   if(self.account_status != STATUS_SIGNUP)
    self.update_attribute(:account_status,STATUS_SIGNUP)
    self.updatelistemails
   end
   
   # try to find an existing token
   token = self.user_tokens.find(:last, :conditions => {:tokentype => UserToken::SIGNUP})
   if(token.nil?)
    token = UserToken.create(:user=>self,:tokentype=>UserToken::SIGNUP, :tokendata => {:email => self.email})
   else
    token.extendtoken
   end
   Notification.create(:notifytype => Notification::CONFIRM_SIGNUP, :user => self, :send_on_create => true, :additionaldata => {:token_id => token.id})
   return true 
  end
  
  def send_resetpass_confirmation
   if(self.account_status == User::STATUS_SIGNUP)
    signuptoken = self.user_tokens.find(:last, :conditions => {:tokentype => UserToken::SIGNUP})
   end
   
   if(!signuptoken.nil?)
    signuptoken.extendtoken
    passtoken = UserToken.create(:user=>self,:tokentype=>UserToken::RESETPASS, :tokendata => {:signuptoken_id => signuptoken.id})
   else
    passtoken = UserToken.create(:user=>self,:tokentype=>UserToken::RESETPASS)
   end

   Notification.create(:notifytype => Notification::CONFIRM_PASSWORD, :user => self, :send_on_create => true, :additionaldata => {:token_id => passtoken.id})
   UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "requested new password confirmation")                            
   return true
  end
  
  def send_signup_confirmation(additionaldata = {})
   tokendata = {:email => self.email}
   if(!additionaldata.blank?)
    tokendata[:invitation_id] = additionaldata[:invitation].id if !additionaldata[:invitation].nil?
   end
   
   # create token
   token = UserToken.create(:user=>self,:tokentype=>UserToken::SIGNUP, :tokendata => tokendata)
   Notification.create(:notifytype => Notification::CONFIRM_SIGNUP, :user => self, :send_on_create => true, :additionaldata => {:token_id => token.id})
   return true
  end
   
  def send_email_confirmation(sendnow=true)
   # update attributes
   if(self.account_status != STATUS_CONFIRMEMAIL or self.emailconfirmed != false)
    self.update_attributes(:account_status => STATUS_CONFIRMEMAIL,:email_event_at => Time.now.utc, :emailconfirmed => false)
    self.updatelistemails
   end
  
   # create token
   token = UserToken.create(:user=>self,:tokentype=>UserToken::EMAIL, :tokendata => {:email => self.email})
   
   # send email or create notification
   Notification.create(:notifytype => Notification::CONFIRM_EMAIL, :user => self, :send_on_create => sendnow, :additionaldata => {:token_id => token.id})
   return true
  end
  
  def send_email_reconfirmation
   # update attributes
   if(self.account_status != STATUS_CONFIRMEMAIL or self.emailconfirmed != false)
    self.update_attributes(:account_status => STATUS_CONFIRMEMAIL,:email_event_at => Time.now.utc, :emailconfirmed => false)
    self.updatelistemails
   end
   
   # create token
   token = UserToken.create(:user=>self,:tokentype=>UserToken::EMAIL, :tokendata => {:email => self.email})
   Notification.create(:notifytype => Notification::RECONFIRM_EMAIL, :user => self, :additionaldata => {:token_id => token.id})
   return true
  end
  
  def send_signup_reconfirmation
   # try to find an existing token
   token = self.user_tokens.find(:last, :conditions => {:tokentype => UserToken::SIGNUP})
   if(token.nil?)
    token = UserToken.create(:user=>self,:tokentype=>UserToken::SIGNUP, :tokendata => {:email => self.email})
   else
    token.extendtoken
   end
   Notification.create(:notifytype => Notification::RECONFIRM_SIGNUP, :user => self, :additionaldata => {:token_id => token.id})
   return true
  end
  
  def is_systemuser?
   return (self.id == 1)
  end
  
  def account_status_string
   if(self.account_status.nil?)
    return 'Contributor'
   end
   
   if(self.retired?)
    return 'Retired Account'
   end
   
   case self.account_status
   when STATUS_CONTRIBUTOR
    displaystring = 'Contributor'
   when STATUS_RETIRED
    displaystring = 'Retired Account'   
   when STATUS_INVALIDEMAIL
    displaystring = 'Invalid Email Address'
   when STATUS_INVALIDEMAIL_FROM_SIGNUP
    displaystring = 'Invalid Email Address (at Signup)'   
   when STATUS_CONFIRMEMAIL
    displaystring = 'Waiting Email Confirmation'      
   when STATUS_REVIEW
    displaystring = 'Pending Review'
   when STATUS_REVIEWAGREEMENT
    displaystring = 'Waiting Agreement Review'
   when STATUS_PARTICIPANT
    displaystring = 'Participant'
   when STATUS_SIGNUP
    displaystring = 'Waiting Signup Confirmation'   
   else
    displaystring = 'UNKNOWN'
   end
   
   return displaystring
  end
  

  
  
   def self.systemuser
    find(1)
   end
   
   def self.systemuserid
    1
   end
   
   def self.anyuser
    0
   end
   
   def self.per_page
    20
   end
   
  
   # used for parameter searching
   def self.find_by_email_or_extensionid_or_id(value,valid_only = true)
     #TODO - there possibly may be an issue here with the conditional
    if(value.to_i != 0)
      # assume id value
      checkfield = 'id'
    elsif (value =~ /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/ )
      checkfield = 'email'
    elsif (value =~ /^[a-zA-Z]+[a-zA-Z0-9]+$/) 
      # looks like a valid extensionid 
      checkfield = 'login'
    else
      return nil
    end
    
    if(valid_only)
      return User.validusers.send("find_by_#{checkfield}",value)
    else
      return User.send("find_by_#{checkfield}",value)
    end
   end
         
   def self.institutioncount
    # returns an orderedhash {institutionobj => count}
    validusers.count(:group => :institution, :conditions => ['institution_id >=1'])    
   end 
      
   def self.locationcount
    # returns an orderedhash {locationobj => count}
    validusers.count(:group => :location, :conditions => ['location_id >=1'])   
   end
   
   def self.positioncount
    # returns an orderedhash {positionobj => count}
    validusers.count(:group => :position, :conditions => ['position_id >=1'])   
   end
   
   def self.top_tags(limit=25)
    validusers.tag_frequency(:order => 'frequency DESC', :limit => limit)
   end
   
   def self.top_tags_by_conditions(conditions,limit=25)
    validusers.tag_frequency(:conditions => conditions, :order => 'frequency DESC', :limit => limit)
   end
       
       
   def self.filterconditions(options={})      
    joins = []
    conditions = []

    conditions << build_date_condition(options)
    #conditions << build_entrytype_condition(options)

    if(options[:community])
      joins << :communities
      conditions << "#{Community.table_name}.id = #{options[:community].id}"
      conditions << "#{Communityconnection.connection_condition(options[:connectiontype])}"
    elsif(options[:communitytype])
      joins << :communities
      conditions << "#{Community.communitytype_condition(options[:communitytype])}"
      conditions << "#{Communityconnection.connection_condition(options[:connectiontype])}"
    end

    # location, position, institution?
    conditions << build_association_conditions(options)
    
    # agreement status?
    conditions << build_agreement_status_conditions(options)
    
    
    # social network?
    if(options[:socialnetwork] or options[:socialnetworks])
      networknames = options[:socialnetworks].nil? ? options[:socialnetwork] :   options[:socialnetworks]
      joins << :social_networks
      conditions << SocialNetwork.get_filter_condition(networknames)
    end

    # agreement status?
    conditions << build_agreement_status_conditions(options)
    
    # announcements?
    if(!options[:announcements].nil?)
      if(options[:announcements])
       conditions << "#{User.table_name}.announcements = 1"
      else
       conditions << "#{User.table_name}.announcements = 0"
      end       
    end
    
    if(options[:allusers].nil? or !options[:allusers])
      conditions << "#{User.table_name}.retired = 0 and #{User.table_name}.vouched = 1 and #{User.table_name}.id != 1"
    end   

    return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}
   end
        
   
   def self.filtered_count(options = {},forcecacheupdate=false)
    cache_key = self.get_cache_key(this_method,options)
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do    
      User.filtered(options).count(:id, :distinct => true)
    end
   end
   
   
   
   def self.total_count(options={},forcecacheupdate=false)
    cache_key = self.get_cache_key(this_method,options)
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do        
      association_conditions = build_association_conditions(options)     
      if(association_conditions.nil?)
       validusers.count
      else
       validusers.count(:conditions => ["#{association_conditions}"])
      end
    end
   end
    
   def self.build_agreement_status_conditions(options={})
    if(options.nil?)
      return nil
    end
        
    if(options[:agreementstatus])
      if(options[:agreementstatus] == 'empty')
       return "users.contributor_agreement IS NULL"
      elsif(options[:agreementstatus] == 'agree')
       return "users.contributor_agreement = 1"
      elsif(options[:agreementstatus] == 'reject')
       return "users.contributor_agreement = 0"
      else
       return nil
      end
    else
      return nil
    end
   end
    
   def self.build_association_conditions(options={})
    conditionsarray = []
    associations_to_check = ['institution','location','position','county']

    associations_to_check.each do |check_association|
      if(association_condition = self.build_association_condition(check_association,options))
       conditionsarray << association_condition
      end
    end

    if(!conditionsarray.blank?)
      return conditionsarray.join(' AND ')
    else
      return nil
    end
   end
  
   # faq user model...
   def get_preference_by_name(name)
    user_preferences.find_by_name(name)
   end

   def publisher?
    pref = user_preferences.find_by_name(UserPreference::SHOW_PUBLISHING_CONTROLS)
    pref && pref.setting == "1"
   end

   def self.count_by_cat_loc(category, location, county)
     user_cond = get_cat_loc_conditions(category, location, county)
     return 0 if !user_cond
     
     return User.count(:all, :conditions => user_cond + " and users.retired = false")
   end

   def self.find_by_cat_loc(category, location, county, page_number = nil)
     user_cond = get_cat_loc_conditions(category, location, county)
     return [] if !user_cond 
     
     if page_number
       page_number = page_number.to_i
       if page_number > 1
         sql_offset = (page_number - 1) * User.per_page
       else
         sql_offset = 0
       end
     else
       sql_offset = nil   
     end
       
     return User.validusers.find(:all, :include => [:expertise_locations, :expertise_counties, :open_questions, :categories], :conditions => user_cond, :order => "users.first_name asc", :offset => sql_offset, :limit => sql_offset ? User.per_page : nil)
   end

   def get_expertise
    # get top-level and subcategories for a user's expertise
    self.categories.find(:all, :include => :children)
   end

   def delete_all_subcat_expertise(category)
    if category.is_top_level?
      self.categories.find(:all, :conditions => {:parent_id => category.id}).each do |subcat|
       self.categories.delete(subcat)
       expertise_event = ExpertiseEvent.new(:category => subcat, :event_type => ExpertiseEvent::EVENT_DELETED, :user => self)
       self.expertise_events << expertise_event
      end
    end
   end

   def get_counties_in_location(location)
    if intersect_counties = expertise_counties_in_location(location)
      return "(#{intersect_counties.map{|c| c.name}.join(', ')})"
    else
      return ""
    end
   end

   def expertise_counties_in_location(location)
    county_intersect = self.expertise_counties & location.expertise_counties
    if county_intersect and county_intersect.length > 0
      return county_intersect
    else
      return nil
    end
   end

   def is_answerer?
    pubsite_answering_role = Role.find_by_name(Role::AUTO_ROUTE)
    widget_answering_role = Role.find_by_name(Role::WIDGET_AUTO_ROUTE)

    if UserRole.find(:first, :conditions => "(role_id = #{pubsite_answering_role.id} or role_id = #{widget_answering_role.id}) and user_id = #{self.id}") and (self.aae_responder == true)
      return true
    else
      return false
    end
   end

   # given a set of users and a ask an expert role, get the users that match the role and other conditions to route to. 
   # if it's a location fallback (ie. there was not a direct match for location), 
   # only retrieve the users that have elected themselves to receive questions from anywhere
   def self.narrow_by_routers(users, route_role, location_fallback = false)
    if users and users.length > 0
      route_role_obj = Role.find_by_name(route_role)
      user_ids = users.collect{|u| u.id}.join(',')

      condition_str = "users.id IN (#{user_ids})"
      if location_fallback
       location_user_ids = UserPreference.find(:all, 
                                  :conditions => "name = '#{UserPreference::AAE_LOCATION_ONLY}' or name = '#{UserPreference::AAE_COUNTY_ONLY}'" +
                                            " and user_id IN (#{user_ids})").collect{|up| up.user_id}.uniq

       condition_str = "users.id IN (#{user_ids}) AND " + 
                  "users.id NOT IN (#{location_user_ids.join(',')}) AND users.aae_responder = true" if (location_user_ids and location_user_ids.length > 0)
      end
      return route_role_obj.users.find(:all, :conditions => condition_str + " and users.retired = false") if route_role_obj
    end

    return []
   end

   def self.uncategorized_wrangler_routers(location = nil, county = nil)
    if (location and county) and (location.fipsid != county.state_fipsid)
      return User.question_wranglers.routers_outside_location 
    end
    
    if county
      expertise_county = ExpertiseCounty.find(:first, :conditions => {:fipsid => county.fipsid}) 
      eligible_wranglers = User.question_wranglers.experts_by_county(expertise_county).question_responders
    end
   
    if location and (!eligible_wranglers or eligible_wranglers.length == 0) 
      eligible_wranglers = get_wranglers_in_location(location)
    end
    
    # get the list of wranglers who don't have the pref set for location only
    
    if !eligible_wranglers or eligible_wranglers.length == 0
      eligible_wranglers = User.question_wranglers.routers_outside_location
    end
    
    return eligible_wranglers
   end
   
   def is_question_wrangler?
    return self.community_ids.include?(Community::QUESTION_WRANGLERS_COMMUNITY_ID)
   end
   
   def open_question_count
    self.open_questions.count
   end

   def get_new_questions
    assigned_questions.count(:conditions => "status_state = #{SubmittedQuestion::STATUS_SUBMITTED} And external_app_id IS NOT NULL")
   end

   def get_resolved
    return resolved_questions.count(:conditions => "status_state in (#{SubmittedQuestion::STATUS_RESOLVED}, #{SubmittedQuestion::STATUS_REJECTED})")
   end
   
   def self.get_answerers_in_category(catid)
     find_by_sql(["Select distinct users.id, users.first_name, users.last_name, users.login, roles.name, roles.id as rid   from users join expertise_areas as ea on users.id=ea.user_id " +
      " left join user_roles on user_roles.user_id=users.id left join roles on user_roles.role_id=roles.id " +
      " where ea.category_id=? order by users.last_name", catid ])
    end
   
   def ever_assigned_questions(options={})
       dateinterval = options[:dateinterval] 

       #get the total number of questions this person was ever assigned
       conditions =[]      
       if(!dateinterval.nil? )
         conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
       end
       conditions << " event_state= #{SubmittedQuestionEvent::ASSIGNED_TO} and recipient_id=#{self.id}"
       return SubmittedQuestion.find(:all, :joins => [:submitted_question_events], :conditions => conditions.compact.join(' AND '), :group => "submitted_question_id")
   end
   

   #
   # AaE Reporting Functions
   #   various functions for AaE calculations - usually in pairs, with a User instance method
   #   and a User class method pairing, as appropriate
   #   builds on the submmitted question event association to return stat values for reporting
  
    
   # aae_handling_event_count 
   #  gets the total number of handling events that occur - grouped by the previous recipient.  
   #  This should essentially be the number of assignments made to an individual - minus any 
   #  open assignments (because we are calculating a rate, and open assignment don't fit into that)
    #  gets the number of those handling events that they handled 
    #  gets the ratio of the two.
   #   returns a hash keyed by user object or user_id if the group_by_id option is present
   def self.aae_handling_event_count(options = {})
    # group by user id's or user objects?
    group_clause = (options[:group_by_id] ? 'previous_handling_recipient_id' : 'previous_handling_recipient')
    # default date interval is 6 months
    dateinterval = options[:dateinterval] || '6 MONTHS'
    
    # get the total number of handling events
    conditions = []      
    if(!dateinterval.nil? )
      conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
    end

    if(!options[:limit_to_handler_ids].blank?)
      conditions << "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})"
    end
    
    if(!options[:submitted_question_filter].nil?)
      totals_hash = SubmittedQuestionEvent.handling_events.submitted_question_filtered(options[:submitted_question_filter]).count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    else
      totals_hash = SubmittedQuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    end
      

    # get the total number of handling events for which I am the previous recipient *and* I was the initiator.
    conditions = ["initiated_by_id = previous_handling_recipient_id"]
    if(!dateinterval.nil?)
      conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
    end
    if(!options[:limit_to_handler_ids].blank?)
      conditions << "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})"
    end
    
    if(!options[:submitted_question_filter].nil?)
      handled_hash = SubmittedQuestionEvent.handling_events.submitted_question_filtered(options[:submitted_question_filter]).count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    else
      handled_hash = SubmittedQuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    end

    # loop through the total list, build a return hash
    # that will return the values per user_id (or user object)
    returnvalues = {}
    totals_hash.keys.each do |groupkey|
      total = totals_hash[groupkey]
      handled = (handled_hash[groupkey].nil?? 0 : handled_hash[groupkey])
      # calculate a floating point ratio
      if(handled > 0)
       ratio = handled.to_f / total.to_f
      else
       ratio = 0
      end
      returnvalues[groupkey] = {:total => total, :handled => handled, :ratio => ratio}
    end

    return returnvalues
   end
   
   # instance method version of aae_handling_event_count
   def aae_handling_event_count(options = {})
    myoptions = options.merge({:group_by_id => true, :limit_to_handler_ids => [self.id]})
    result = User.aae_handling_event_count(myoptions)
    if(result and result[self.id])
      returnvalues = result[self.id]
    else
      returnvalues = {:total => 0, :handled => 0, :ratio => 0}
    end
    return returnvalues
   end

   # aae_handling_average 
   #   gets the handling average (in seconds) for those conditions where the 
   #   person assigned the question handles it.  
   def self.aae_handling_average(options = {})
    # group by user id's or user objects?
    group_clause = (options[:group_by_id] ? 'previous_handling_recipient_id' : 'previous_handling_recipient')
    # default date interval is 6 months
    dateinterval = options[:dateinterval] || '6 MONTHS'
    
    # get the total number of handling events for which I am the previous recipient *and* I was the initiator.
    conditions = ["initiated_by_id = previous_handling_recipient_id"]
    if(!dateinterval.nil?)
      conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
    end

    if(options[:limit_to_handler_ids])
      conditions << "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})"
    end
    
    if(!options[:submitted_question_filter].nil?)
      handlingaverages = SubmittedQuestionEvent.handling_events.submitted_question_filtered(options[:submitted_question_filter]).average('duration_since_last_handling_event', :conditions => conditions.compact.join(' AND '),:group => group_clause)
    else
      handlingaverages = SubmittedQuestionEvent.handling_events.average('duration_since_last_handling_event', :conditions => conditions.compact.join(' AND '),:group => group_clause)
    end
    
    return handlingaverages
   end
   
   # instance method version of aae_handling_average
   def aae_handling_average(options = {})
    myoptions = options.merge({:group_by_id => true, :limit_to_handler_ids => [self.id]})
    result = User.aae_handling_average(myoptions)
    if(result and result[self.id])
      returnvalues = result[self.id]
    else
      returnvalues = 0
    end
    return returnvalues
   end

   # aae_hold_average 
   #   gets the hold average (in seconds) for a person
   #   the hold average is how long a person holds a question until they handle it or 
   #   it gets taken away from them - it's a measure of how long things can be delayed
   #   on average if that person is assigned something.
   def self.aae_hold_average(options = {})
    # group by user id's or user objects?
    group_clause = (options[:group_by_id] ? 'previous_handling_recipient_id' : 'previous_handling_recipient')
    # default date interval is 6 months
    dateinterval = options[:dateinterval] || '6 MONTHS'
    
    # get the total number of handling events for which I am the previous recipient *and* I was the initiator.
    conditions = []
    if(!dateinterval.nil?)
      conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
    end

    if(options[:limit_to_handler_ids])
      conditions << "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})"
    end
    
    if(!options[:submitted_question_filter].nil?)
      handlingaverages = SubmittedQuestionEvent.handling_events.submitted_question_filtered(options[:submitted_question_filter]).average('duration_since_last_handling_event', :conditions => conditions.compact.join(' AND '),:group => group_clause)
    else
      handlingaverages = SubmittedQuestionEvent.handling_events.average('duration_since_last_handling_event', :conditions => conditions.compact.join(' AND '),:group => group_clause)
    end
    
    return handlingaverages
   end

   # instance method version of aae_hold_average
   def aae_hold_average(options = {})
    myoptions = options.merge({:group_by_id => true, :limit_to_handler_ids => [self.id]})
    result = User.aae_hold_average(myoptions)
    if(result and result[self.id])
      returnvalues = result[self.id]
    else
      returnvalues = 0
    end
    return returnvalues
   end

   # aae_response_event_count
   #  gets the total number of handling events that occur - grouped by the previous recipient.  
   #  This should essentially be the number of assignments made to an individual - minus any 
   #  open assignments (because we are calculating a rate, and open assignment don't fit into that)
   #  NOTE: this is the same total used in the aae_handling_event_count 
   #   gets the total response events for that previous recipient
   #  calculates a ratio of the two
   #   returns a hash keyed by user object or user_id if the group_by_id option is present
   def self.aae_response_event_count(options = {})
    # group by user id's or user objects?
    group_clause = (options[:group_by_id] ? 'previous_handling_recipient_id' : 'previous_handling_recipient')
    # default date interval is 6 months
    dateinterval = options[:dateinterval] || '6 MONTHS'
    
    # get the total number of handling events
    conditions = []      
    if(!dateinterval.nil? )
      conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
    end

    if(!options[:limit_to_handler_ids].blank?)
      conditions << "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})"
    end
    
    if(!options[:submitted_question_filter].nil?)
      totals_hash = SubmittedQuestionEvent.handling_events.submitted_question_filtered(options[:submitted_question_filter]).count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    else
      totals_hash = SubmittedQuestionEvent.handling_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    end
      

    # get the total number of handling events for which I am the previous recipient *and* I was the initiator.
    conditions = ["initiated_by_id = previous_handling_recipient_id"]
    if(!dateinterval.nil?)
      conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
    end
    if(!options[:limit_to_handler_ids].blank?)
      conditions << "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})"
    end
    
    if(!options[:submitted_question_filter].nil?)
      responded_hash = SubmittedQuestionEvent.response_events.submitted_question_filtered(options[:submitted_question_filter]).count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    else
      responded_hash = SubmittedQuestionEvent.response_events.count(:all, :conditions => conditions.compact.join(' AND '), :group => group_clause)
    end

    # loop through the total list, build a return hash
    # that will return the values per user_id (or user object)
    returnvalues = {}
    totals_hash.keys.each do |groupkey|
      total = totals_hash[groupkey]
      responded = (responded_hash[groupkey].nil?? 0 : responded_hash[groupkey])
      # calculate a floating point ratio
      if(responded > 0)
       ratio = responded.to_f / total.to_f
      else
       ratio = 0
      end
      returnvalues[groupkey] = {:total => total, :responded => responded, :ratio => ratio}
    end

    return returnvalues
   end
   
   # instance method version of aae_handling_event_count
   def aae_response_event_count(options = {})
    myoptions = options.merge({:group_by_id => true, :limit_to_handler_ids => [self.id]})
    result = User.aae_response_event_count(myoptions)
    if(result and result[self.id])
      returnvalues = result[self.id]
    else
      returnvalues = {:total => 0, :handled => 0, :ratio => 0}
    end
    return returnvalues
   end

   # aae_response_average 
   #   gets the handling average (in seconds) for those conditions where the 
   #   person assigned the question responds to it. The response is calculated
   #  by the time from when it was assigned, not the time of when the question
   #  came in. 
   def self.aae_response_average(options = {})
    # group by user id's or user objects?
    group_clause = (options[:group_by_id] ? 'previous_handling_recipient_id' : 'previous_handling_recipient')
    # default date interval is 6 months
    dateinterval = options[:dateinterval] || '6 MONTHS'
    
    # get the total number of handling events for which I am the previous recipient *and* I was the initiator.
    conditions = ["initiated_by_id = previous_handling_recipient_id"]
    if(!dateinterval.nil?)
      conditions << SubmittedQuestionEvent.build_date_condition({:dateinterval => dateinterval})
    end

    if(options[:limit_to_handler_ids])
      conditions << "previous_handling_recipient_id IN (#{options[:limit_to_handler_ids].join(',')})"
    end
    
    if(!options[:submitted_question_filter].nil?)
      responseaverages = SubmittedQuestionEvent.response_events.submitted_question_filtered(options[:submitted_question_filter]).average('duration_since_last_handling_event', :conditions => conditions.compact.join(' AND '),:group => group_clause)
    else
      responseaverages = SubmittedQuestionEvent.response_events.average('duration_since_last_handling_event', :conditions => conditions.compact.join(' AND '),:group => group_clause)
    end
    
    return responseaverages
   end    

   # instance method version of aae_response_average
   def aae_response_average(options = {})
    myoptions = options.merge({:group_by_id => true, :limit_to_handler_ids => [self.id]})
    result = User.aae_response_average(myoptions)
    if(result and result[self.id])
      returnvalues = result[self.id]
    else
      returnvalues = 0
    end
    return returnvalues
   end
 
  def get_avg_resp_time(options={})
     statuses = [ "", " #{SubmittedQuestion::STATUS_RESOLVED}", "#{SubmittedQuestion::STATUS_REJECTED}","#{SubmittedQuestion::STATUS_NO_ANSWER}"]
     results = []
     conditions = []; addedstat = nil
     dateinterval = options[:dateinterval]
      if(!dateinterval.nil?)
        conditions << SubmittedQuestion.build_date_condition({:dateinterval => dateinterval})
      end
     conditions << " event_state=#{SubmittedQuestionEvent::ASSIGNED_TO} and recipient_id=#{self.id} and resolved_by=#{self.id} "
     statuses.each do |stat|
        if (addedstat)    # do not keep accumulating conditions meant to replace each other
           conditions.delete_at(conditions.size - 1)
        end
        if stat.length > 0
           conditions << " status_state=#{stat}"
           addedstat = 1
        end       #average below is from assigned to resolved
        avgstd = SubmittedQuestionEvent.find(:all, :select => " count(*) as count_all, avg(timestampdiff(second, submitted_question_events.created_at, resolved_at)) as ra, stddev(timestampdiff(second, submitted_question_events.created_at, resolved_at)) as stdev ",
        :joins => [:submitted_question], :conditions => conditions.compact.join(' AND '))
        
        results << [(avgstd[0].ra.to_f)/(60*60), (avgstd[0].stdev.to_f)/(60*60), avgstd[0].count_all]
    end
    results   
  end  

    def self.find_state_users(options={})
       dateinterval = options[:dateinterval]

        conditions = []      
        if(!dateinterval.nil? )
          conditions << User.build_date_condition({:dateinterval => dateinterval})
        end
  
        if options[:county]
          conditions << " county_id=#{options[:county]} "
        else
          if options[:location]
               conditions << " location_id = #{options[:location].id} "
          end
        end
       
      @users=User.with_scope(:find => { :conditions => conditions.compact.join(' AND '), :limit => 100}) do
        paginate(options[:numparm].to_sym, options[:args])
      end
    end
    
  def self.submitted_question_resolvers_by_category(category)
   # TODO: does external_app_id != NULL matter?
   # TODO: should this be validusers?
   self.find(:all, :select => "users.*, count(submitted_questions.id) as resolved_count", :joins => {:resolved_questions => :categories}, \
   :conditions => ['categories.id = ? and submitted_questions.external_app_id IS NOT NULL',category.id], :group => 'users.id', \
   :order => 'users.last_name,users.first_name')
  end
   
  def self.cleanup_accounts
   # TODO
  end
  
  def expire_password
   # note, will not call before_update (good, not encrypting '') 
   # but it will call after_update to update the chat_account password
   self.update_attribute('password','')
  end
  
  def self.expire_passwords
   # TODO: en masse password update using SQL
  end
  
  protected
  
  def check_status
   logger.debug "Account Status = #{self.account_status}"
   if (!self.retired? and self.account_status != STATUS_SIGNUP)
    if (!self.emailconfirmed?)
      self.account_status = STATUS_CONFIRMEMAIL if (account_status != STATUS_INVALIDEMAIL and account_status != STATUS_INVALIDEMAIL_FROM_SIGNUP)
    elsif (!self.vouched?)
      self.account_status = STATUS_REVIEW
    elsif self.contributor_agreement.nil?
      self.account_status = STATUS_REVIEWAGREEMENT
    elsif not self.contributor_agreement
      self.account_status = STATUS_PARTICIPANT
    else
      self.account_status = STATUS_CONTRIBUTOR
    end
   end
   logger.debug "Account End Status = #{self.account_status}"
    
  end
  
  
  def encrypt_password_string(clear_password_string)
   Digest::SHA1.hexdigest(clear_password_string)
  end
   
  def set_encrypted_password
   self.password = self.encrypt_password_string(self.password) if (!password.empty? && self.password_changed?)
  end
  
  def convert_phonenumber
   self.phonenumber = self.phonenumber.to_s.gsub(/[^0-9]/, '') if self.phonenumber
  end
  
  def generate_feedkey
   if(self.feedkey.nil? or self.feedkey == '' or self.password_changed?)
    self.feedkey = Digest::SHA1.hexdigest(self.password + 'feedkey!feedkey!feedkey!' + Time.now.to_s)
   end
  end
    
  def self.get_wranglers_in_location(location)
   expertise_location = ExpertiseLocation.find(:first, :conditions => {:fipsid => location.fipsid})
   # get experts signed up to receive questions from that location but take out anyone who 
   # elected to only receive questions in their county
   location_wranglers = User.question_wranglers.experts_by_location(expertise_location).question_responders - User.experts_by_county_only
  end
  
  def self.get_cat_loc_conditions(category, location, county)
    if category
      filtered_users = category.users.collect{|cu| cu.id}.join(',')
      return nil if !filtered_users or filtered_users.strip == ''
    end

    if location
      (filtered_users and filtered_users != '') ? loc_cond = "users.id IN (#{filtered_users})" : loc_cond = nil 
      # not only pull experts that marked the location in AaE prefs, but also the experts who marked 
      # the location in their People profile.
      # this was done so that when searching for experts by location, all experts affiliated with a location will 
      # be returned, not just the ones who remembered to mark it in their AaE prefs.
      filtered_users = self.experts_from_aae_or_people_location(location.fipsid).find(:all, :conditions => loc_cond).collect{|lu| lu.id}.join(',')
      return nil if !filtered_users or filtered_users.strip == ''
    end

    if location and county
      county_cond = "users.id IN (#{filtered_users})"
      filtered_users = county.users.find(:all, :conditions => county_cond).collect{|cu| cu.id}.join(',') 
      return nil if !filtered_users or filtered_users.strip == ''
    end

    (filtered_users and filtered_users != '') ? (return "users.id IN (#{filtered_users})") : (return nil)
  end
  
end
