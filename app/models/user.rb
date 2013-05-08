# === COPYRIGHT:
# Copyright (c) 2005-2009 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'
class User < Account
  include ActionController::UrlWriter

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
     
  has_many :sentinvitations, :class_name  => "Invitation"
  has_many :user_tokens, :dependent => :destroy
  has_many :emailtokens, :class_name  => "UserToken", :conditions => "user_tokens.tokentype = #{UserToken::EMAIL}"
  
  has_many :privacy_settings
  
  has_many :opie_approvals, :dependent => :destroy
  has_one :chat_account, :dependent => :destroy
  has_one :google_account, :dependent => :destroy
  
  has_many :email_aliases
  
  has_many :user_events, :order => 'created_at DESC', :dependent => :destroy
  has_many :activities, :order => 'created_at DESC', :dependent => :destroy
  
  has_many :notifications, :foreign_key => "account_id", :dependent => :destroy
      
  belongs_to :position
  belongs_to :location
  belongs_to :county

  has_many :social_networks, :dependent => :destroy

  has_many :communityconnections, :dependent => :destroy
  has_many :communities, :through => :communityconnections, :select => "communityconnections.connectiontype as connectiontype, communityconnections.sendnotifications as sendnotifications, communities.*", :order => "communities.name"
    
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
  
  has_many :api_keys
  has_many :api_key_events, :through => :api_keys
  has_one  :directory_item_cache
  
  # has_many :invitations
    
  after_save :update_chataccount
  after_save :update_google_account
  after_save :update_email_aliases
  after_save :touch_lists
  after_save :update_person
  
  before_validation :convert_phonenumber
  before_save :check_status, :generate_feedkey
  
  validates_length_of :phonenumber, :is => 10, :allow_blank => true
  validates_presence_of :last_name, :first_name
  
  # scopers
  named_scope :validusers, :conditions => {:retired => false,:vouched => true}
  named_scope :notsystem_or_admin, :conditions => ["(#{self.table_name}.id NOT IN (#{AppConfig.configtable['reserved_uids'].join(',')}) and is_admin = 0)"]
  named_scope :unconfirmedemail, :conditions => ["emailconfirmed = ? AND account_status != ?",false,User::STATUS_SIGNUP]
  named_scope :pendingsignups, :conditions => {:account_status => User::STATUS_SIGNUP}
  named_scope :active, :conditions => {:retired => false}
  
  named_scope :filtered, lambda {|options| filterconditions(options)}  
  
  named_scope :missingtags,  :joins => "LEFT JOIN taggings ON (accounts.id = taggings.taggable_id AND taggings.taggable_type = 'User')", :conditions => 'taggings.id IS NULL'
  named_scope :missingnetworks, :joins => "LEFT JOIN social_networks ON accounts.id = social_networks.user_id",  :conditions => 'social_networks.id IS NULL'
    
  named_scope :date_users, lambda { |date1, date2| { :conditions => (date1 && date2) ?   [ " TRIM(DATE(accounts.created_at)) between ? and ?", date1, date2] : "true" } }
  
  named_scope :vouchlist, :conditions => ["vouched = 0 AND retired = 0 AND account_status != #{User::STATUS_SIGNUP} and emailconfirmed=1"]
  named_scope :list_eligible, :conditions => {:emailconfirmed => true, :retired => false, :vouched => true}
      
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
      when 'time_zone'
       returnhash.merge!({:phone => self.has_time_zone? ? '' : self.time_zone})
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
  
  def is_validuser?
    if(self.retired? or !self.vouched? or self.account_status == User::STATUS_SIGNUP)
      return false
    else
      return true
    end
  end
    
  
  def update_chataccount
    if(!AppConfig.configtable['reserved_uids'].include?(self.id))
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
    return true
  end
  
  def update_google_account
   # remove google account if retired
   if (self.retired? or !self.vouched? or self.account_status == User::STATUS_SIGNUP)
    if(!self.google_account.nil?)
      self.google_account.suspended = true
      self.google_account.save
    end
   else
    if(!self.google_account.nil?)
      self.google_account.suspended = false
      self.google_account.save
    else
      self.create_google_account
    end
   end
   return true
  end
  
  def update_email_aliases
   # remove email aliases if retired
   if (self.retired? or !self.vouched? or self.account_status == User::STATUS_SIGNUP)
    if(!self.email_aliases.blank?)
      self.email_aliases.each do |ea|
        ea.disabled = true
        ea.save
      end
    end
   else
    if(!self.email_aliases.blank?)
      self.email_aliases.each do |ea|
        if(ea.alias_type == EmailAlias::INDIVIDUAL_FORWARD and (self.account_status == User::STATUS_CONFIRMEMAIL or self.email_changed?))
          # do nothing
        else
          ea.disabled = false
          ea.save
        end
      end
    else
      EmailAlias.create(:alias_type => EmailAlias::INDIVIDUAL_FORWARD, :user => self)
    end
   end
  end
  
  def email_forward
    self.email_aliases.find_by_mail_alias(self.login)
  end
  
  def switch_to_apps_email
    forward = self.email_forward
    if(!forward.nil?)
      forward.update_attribute(:alias_type,EmailAlias::INDIVIDUAL_GOOGLEAPPS)
    end
  end
  
  # retires the user account, will clear out list and community connections, and reroute any assigned questions  
  #
  # @param [User] retired_by User/Account doing the retiring
  # @param [String] retired_reason Retiring reason     
  def retire(retired_by = User.systemuser, retired_reason = 'unknown')
    self.retired = true
    self.retired_at = Time.now()
    if(self.additionaldata.nil?)
      self.additionaldata = {:retired_by => retired_by.id, :retired_reason => retired_reason}
    else
      self.additionaldata = self.additionaldata.merge({:retired_by => retired_by.id, :retired_reason => retired_reason})
    end
    if(self.save)
      AdminEvent.log_event(retired_by, AdminEvent::RETIRE_ACCOUNT,{:extensionid => self.login, :reason => retired_reason})
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "account retired by #{retired_by.login}")                                              
      self.clear_all_community_connections
      return true
    else
      return false
    end
  end
  
  # goes through and retires all accounts that have been ignored in review for the last 14 days
  #
  # @param [String] retired_reason Retiring reason     
  def self.retire_ignored_account_requests(retired_reason = 'No one vouched for the account within 14 days')
    cutoff = Time.now.utc - 14.days
    retirelist = self.vouchlist.all(:conditions => "email_event_at < '#{cutoff.to_s(:db)}'")
    retirelist.each do |user|
      user.retire(User.systemuser,retired_reason)
    end
    return retirelist.size
  end
     
  def clear_all_community_connections
   # WARNING WARNING DANGER WILL ROBINSON
   mycommunities = {}
   self.communities.each do |community| 
     mycommunities[community.name] = community.id
     community.touch # update community timestamp so lists will update next run
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
    # this is silly, but it's a quick fix that I'm sure will stick around
    # forever so that an account won't get re-retired each day after enabling
    self.email_event_at = Time.now.utc
    if(self.save)
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
    if(!self.additionaldata.nil? and !self.additionaldata[:signup_institution_id].nil?)
      self.change_profile_community(Community.find(self.additionaldata[:signup_institution_id])) if self.additionaldata[:signup_institution_id] != '0'
    end
    return true
   else
    return false
   end
  end
  
  def set_new_password(token,password)
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
   if(self.save)      
    self.user_tokens.resetpassword.delete_all
    if(didsignup)
      self.user_tokens.signups.delete_all
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "signup")
      Activity.log_activity(:user => self, :creator => self, :activitycode => Activity::SIGNUP, :appname => 'local')      
    end
    UserEvent.log_event(:etype => UserEvent::PROFILE,:user => self,:description => "set new password") 
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
   if (self.email =~ /edu$|gov$|mil$/i)
    return true
   else
    return false
   end
  end
  
  def lists
    list_of_lists = []
    if(self.is_validuser? and self.emailconfirmed?)    
      if(self.announcements?)
        list_of_lists << List.find_announce_list
      end
      self.communities.each do |community|
        case community.connectiontype
        when 'member'
          list_of_lists += community.lists.where("connectiontype = 'joined'")
        when 'leader'
          list_of_lists += community.lists.where("connectiontype IN ('joined','leaders','interested')")
        when 'wantstojoin'
          list_of_lists += community.lists.where("connectiontype = 'interested'")
        when 'interest'
          list_of_lists += community.lists.where("connectiontype = 'interested'")
        end
      end
    end
    list_of_lists.compact
  end
  
  def touch_lists
    self.lists.each do |l|
      l.touch
    end
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
    # question wrangler community?
    if(community.id == Community::QUESTION_WRANGLERS_COMMUNITY_ID)
      if(connectiontype == 'leader' or connectiontype == 'member')
        self.update_attribute(:is_question_wrangler, true)
      end
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
        # question wrangler community?
        if(community.id == Community::QUESTION_WRANGLERS_COMMUNITY_ID)
          self.update_attribute(:is_question_wrangler, false)
        end
        community.touch
       end
      else
       if(community.is_institution?)
        Community.find(Community::INSTITUTIONAL_TEAMS_COMMUNITY_ID).remove_user_from_membership(self,User.systemuser)
       end
       connection.destroy
       # question wrangler community?
       if(community.id == Community::QUESTION_WRANGLERS_COMMUNITY_ID)
         self.update_attribute(:is_question_wrangler, false)
       end
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
      Notification.create(:notifytype => options[:notificationcode], :account => self, :creator => connector, :community => community)
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
      community.touch_lists
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
           
  def is_sudoer?
   return AppConfig.configtable['sudoers'][self.login.downcase]
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
   end
   token = UserToken.create(:user=>self,:tokentype=>UserToken::EMAIL, :tokendata => {:email => self.email, :oldemail => old_email_address})
   Notification.create(:notifytype => Notification::CONFIRM_EMAIL_CHANGE, :account => self, :send_on_create => true, :additionaldata => {:token_id => token.id})   
   return true
  end
  
  def resend_signup_confirmation(options={})
   if(self.account_status != STATUS_SIGNUP)
    self.update_attribute(:account_status,STATUS_SIGNUP)
   end
   
   # try to find an existing token
   token = self.user_tokens.find(:last, :conditions => {:tokentype => UserToken::SIGNUP})
   if(token.nil?)
    token = UserToken.create(:user=>self,:tokentype=>UserToken::SIGNUP, :tokendata => {:email => self.email})
   else
    token.extendtoken
   end
   Notification.create(:notifytype => Notification::CONFIRM_SIGNUP, :account => self, :send_on_create => true, :additionaldata => {:token_id => token.id})
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

   Notification.create(:notifytype => Notification::CONFIRM_PASSWORD, :account => self, :send_on_create => true, :additionaldata => {:token_id => passtoken.id})
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
   Notification.create(:notifytype => Notification::CONFIRM_SIGNUP, :account => self, :send_on_create => true, :additionaldata => {:token_id => token.id})
   return true
  end
   
  def send_email_confirmation(sendnow=true)
   # update attributes
   if(self.account_status != STATUS_CONFIRMEMAIL or self.emailconfirmed != false)
    self.update_attributes(:account_status => STATUS_CONFIRMEMAIL,:email_event_at => Time.now.utc, :emailconfirmed => false)
   end
  
   # create token
   token = UserToken.create(:user=>self,:tokentype=>UserToken::EMAIL, :tokendata => {:email => self.email})
   
   # send email or create notification
   Notification.create(:notifytype => Notification::CONFIRM_EMAIL, :account => self, :send_on_create => sendnow, :additionaldata => {:token_id => token.id})
   return true
  end
  
  def send_email_reconfirmation
   # update attributes
   if(self.account_status != STATUS_CONFIRMEMAIL or self.emailconfirmed != false)
    self.update_attributes(:account_status => STATUS_CONFIRMEMAIL,:email_event_at => Time.now.utc, :emailconfirmed => false)
   end
   
   # create token
   token = UserToken.create(:user=>self,:tokentype=>UserToken::EMAIL, :tokendata => {:email => self.email})
   Notification.create(:notifytype => Notification::RECONFIRM_EMAIL, :account => self, :additionaldata => {:token_id => token.id})
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
   Notification.create(:notifytype => Notification::RECONFIRM_SIGNUP, :account => self, :additionaldata => {:token_id => token.id})
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
  
   def self.filteredparameters
     filteredparams_list = []
     # list everything that User.filterconditions handles
     # build_date_condition
     filteredparams_list += [:dateinterval,:datefield]
     # community params
     filteredparams_list += [:community,:communitytype,:connectiontype]
     # build_association_conditions
     filteredparams_list += [:institution,:location,:position, :county]
     # build_agreement_status_conditions
     filteredparams_list += [:agreementstatus]
     # others, socialnetwork name, announcements, allusers
     filteredparams_list += [{:socialnetwork => :string},{:announcements => :boolean},{:allusers => :boolean}]
     filteredparams_list
   end     
       
   def self.filterconditions(options={})      
    joins = []
    conditions = []

    conditions << build_date_condition(options)

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
    if(options[:socialnetwork])
      joins << :social_networks
      conditions << SocialNetwork.get_filter_condition(options[:socialnetwork])
    end

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
       return "accounts.contributor_agreement IS NULL"
      elsif(options[:agreementstatus] == 'agree')
       return "accounts.contributor_agreement = 1"
      elsif(options[:agreementstatus] == 'reject')
       return "accounts.contributor_agreement = 0"
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
  
   
  def post_account_review_request
    if(self.vouched?)
      return true
    end

    request_options = {}
    request_options['account_review_key'] = AppConfig.configtable['account_review_key']
    request_options['idstring'] = self.login
    request_options['email'] = self.email
    request_options['fullname'] = self.fullname
    if (!self.additionaldata.blank? and !self.additionaldata[:signup_affiliation].blank?)
      request_options['additional_information'] = self.additionaldata[:signup_affiliation]
    end

    begin
    raw_result = RestClient.post(AppConfig.configtable['account_review_url'],
                             request_options.to_json,
                             :content_type => :json, :accept => :json)
    rescue StandardError => e
      raw_result = e.response
    end
    result = JSON.parse(raw_result.gsub(/'/,"\""))
    if(result['success'])
      if(!self.additionaldata.blank?)
        self.additionaldata = self.additionaldata.merge({:vouch_results => {:success => true, :request_id => result['question_id']}})
      else
        self.additionaldata = {:vouch_results => {:success => true, :request_id => result['question_id']}}
      end
      self.save!
      return true
    else
      if(!self.additionaldata.blank?)
        self.additionaldata = self.additionaldata.merge({:vouch_results => {:success => false, :error => result['message']}})
      else
        self.additionaldata = {:vouch_results => {:success => false, :error => result['message']}}
      end
      self.save!
      return false
    end
  end

  def create_admin_account
    admin_user = User.new
    admin_user.attributes = self.attributes
    admin_user.login = "#{self.login}-admin"
    admin_user.is_admin = true
    admin_user.email = "#{admin_user.login}@extension.org"
    admin_user.primary_account_id = self.id
    admin_user.password = ''
    admin_user.save
    admin_user
  end

  def quoted_value_or_null(value)
    value.blank? ? 'NULL' : ActiveRecord::Base.quote_value(value)
  end

  def update_person
    # always make it people
    openid_url_for_update = "https://people.extension.org/#{self.login}"
    if(person = Person.find_by_id(self.id))
      person.update_attributes({:uid => openid_url_for_update, 
                                :first_name => self.first_name, 
                                :last_name => self.last_name, 
                                :is_admin => self.is_admin, 
                                :retired => self.retired})

    elsif(self.vouched?)
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT IGNORE INTO #{Person.table_name} (id,uid,first_name,last_name,is_admin,retired,created_at,updated_at)
      SELECT  #{self.id}, 
              #{ActiveRecord::Base.quote_value(openid_url_for_update)},
              #{quoted_value_or_null(self.first_name)},
              #{quoted_value_or_null(self.last_name)},
              #{self.retired},
              #{self.is_admin},
              #{ActiveRecord::Base.quote_value(self.created_at.to_s(:db))},
              #{ActiveRecord::Base.quote_value(self.updated_at.to_s(:db))}
      END_SQL

      self.connection.execute(query)
    end
  end
  
  protected
  
  def check_status
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
  end
    
  def convert_phonenumber
   self.phonenumber = self.phonenumber.to_s.gsub(/[^0-9]/, '') if self.phonenumber
  end
  
  def generate_feedkey
   if(self.feedkey.nil? or self.feedkey == '' or self.password_changed?)
    self.feedkey = Digest::SHA1.hexdigest(self.password + 'feedkey!feedkey!feedkey!' + Time.now.to_s)
   end
  end
    
end
