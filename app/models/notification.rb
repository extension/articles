# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Notification < ActiveRecord::Base
  
  NONE = 1
  
  ###############################
  #  People Notifications
  
  NOTIFICATION_PEOPLE = [100,999]   # 'people'
  
  COMMUNITY_USER_JOIN = 101
  COMMUNITY_USER_WANTSTOJOIN = 102
  COMMUNITY_USER_LEFT= 103
  COMMUNITY_USER_ACCEPT_INVITATION= 104
  COMMUNITY_USER_DECLINE_INVITATION= 105
  COMMUNITY_USER_NOWANTSTOJOIN= 106
  COMMUNITY_USER_INTEREST = 107
  COMMUNITY_USER_NOINTEREST = 108

  COMMUNITY_LEADER_INVITELEADER = 201
  COMMUNITY_LEADER_INVITEMEMBER = 202
  COMMUNITY_LEADER_RESCINDINVITATION = 203
  COMMUNITY_LEADER_INVITEREMINDER = 204
  COMMUNITY_LEADER_ADDLEADER = 301
  COMMUNITY_LEADER_ADDMEMBER = 302
  COMMUNITY_LEADER_REMOVELEADER = 401
  COMMUNITY_LEADER_REMOVEMEMBER = 402
  
  # eXtensionID Invitation
  INVITATION_TO_EXTENSIONID = 500
  INVITATION_ACCEPTED = 501
  
  CONFIRM_EMAIL = 501
  RECONFIRM_EMAIL = 502
  RECONFIRM_SIGNUP = 503
  CONFIRM_PASSWORD = 504
  WELCOME = 505
  ACCOUNT_REVIEW = 506
  CONFIRM_EMAIL_CHANGE = 507
  CONFIRM_SIGNUP = 508
    
  ## Other User actions
  # TODO: new account created?
  
  ##########################################
  #  Ask an Expert Notifications - Internal

  NOTIFICATION_AAE_INTERNAL = [1000,1999]   # 'aae-internal'
  AAE_ASSIGNMENT = 1001  # assignment notification
  AAE_REASSIGNMENT = 1002  # reassignment notification
  AAE_ESCALATION = 1003  # escalation notification
  AAE_PUBLIC_EDIT = 1004  # a public user edited their question
  AAE_PUBLIC_COMMENT = 1005 # a public user posted another comment
    
  ##########################################
  #  Ask an Expert Notifications - Public
  
  NOTIFICATION_AAE_PUBLIC = [2000,2999]   # 'aae-public'
  AAE_PUBLIC_EXPERT_RESPONSE = 2001  # notification of an expert response, also "A Space Odyssey"
  AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT = 2010  # notification of submission, also "The Year We Make Contact"
  
  # method names for sending notificationmailer mailers for each notification
  MAILERMETHODS = {}
  MAILERMETHODS[COMMUNITY_USER_JOIN] = ['community_user']
  MAILERMETHODS[COMMUNITY_USER_WANTSTOJOIN] = ['community_user']
  MAILERMETHODS[COMMUNITY_USER_LEFT] = ['community_user']
  MAILERMETHODS[COMMUNITY_USER_ACCEPT_INVITATION] = ['community_user']
  MAILERMETHODS[COMMUNITY_USER_DECLINE_INVITATION] = ['community_user']
  MAILERMETHODS[COMMUNITY_USER_NOWANTSTOJOIN] = ['community_user']
  MAILERMETHODS[COMMUNITY_USER_INTEREST] = ['community_user']
  MAILERMETHODS[COMMUNITY_USER_NOINTEREST] = ['community_user']
  MAILERMETHODS[COMMUNITY_LEADER_INVITELEADER] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[COMMUNITY_LEADER_INVITEMEMBER] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[COMMUNITY_LEADER_RESCINDINVITATION] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[COMMUNITY_LEADER_INVITEREMINDER] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[COMMUNITY_LEADER_ADDLEADER] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[COMMUNITY_LEADER_ADDMEMBER] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[COMMUNITY_LEADER_REMOVELEADER] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[COMMUNITY_LEADER_REMOVEMEMBER] = ['community_change_notifygroup','community_change_notifyuser']
  MAILERMETHODS[INVITATION_TO_EXTENSIONID] = ['invitation_to_extensionid']    
  MAILERMETHODS[INVITATION_ACCEPTED] = ['accepted_extensionid_invitation']    
  MAILERMETHODS[CONFIRM_EMAIL] = ['confirm_email']      
  MAILERMETHODS[RECONFIRM_EMAIL] = ['reconfirm_email']    
  MAILERMETHODS[RECONFIRM_SIGNUP] = ['reconfirm_signup']    
  MAILERMETHODS[CONFIRM_PASSWORD] = ['confirm_password']    
  MAILERMETHODS[WELCOME] = ['welcome']    
  MAILERMETHODS[ACCOUNT_REVIEW] = ['review_request']   
  MAILERMETHODS[CONFIRM_EMAIL_CHANGE] = ['confirm_email_change']      
  MAILERMETHODS[CONFIRM_SIGNUP] = ['confirm_signup']    
  MAILERMETHODS[AAE_ASSIGNMENT] = ['aae_assigned']  
  MAILERMETHODS[AAE_REASSIGNMENT] = ['aae_reassigned']    
  # TODO: MAILERMETHODS[AAE_ESCALATION] = ['todo']    
  MAILERMETHODS[AAE_PUBLIC_EDIT] = ['aae_public_edit']    
  MAILERMETHODS[AAE_PUBLIC_EXPERT_RESPONSE] = ['aae_public_response']    
  MAILERMETHODS[AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT] = ['aae_public_submission'] 
  MAILERMETHODS[AAE_PUBLIC_COMMENT] = ['aae_public_comment']   
  
  # TODO: add description labels that can get strings from the locale tabel describing each 
  

  belongs_to :user
  belongs_to :community # for many of the notification types
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  serialize :additionaldata
  
  before_create :createnotification?
  after_create :send_now?
  
  named_scope :tosend, :conditions => {:sent_email => false,:send_error => false}, :order => "created_at ASC"
  named_scope :aae_internal, :conditions => ["notifytype BETWEEN (#{NOTIFICATION_AAE_INTERNAL[0]} and #{NOTIFICATION_AAE_INTERNAL[1]})"]
  named_scope :aae_public, :conditions => ["notifytype BETWEEN (#{NOTIFICATION_AAE_PUBLIC[0]} and #{NOTIFICATION_AAE_PUBLIC[1]})"] 
  named_scope :people, :conditions => ["notifytype BETWEEN (#{NOTIFICATION_PEOPLE[0]} and #{NOTIFICATION_PEOPLE[1]})"] 
  
  def send_email
    if(MAILERMETHODS[self.notifytype].blank?)
      return false
    else
      MAILERMETHODS[self.notifytype].each do |methodname|
        begin 
          NotificationMailer.send("deliver_#{methodname}",self)
        rescue Exception => exception
          if(!self.additionaldata.nil?)
            additionaldata = self.additionaldata.merge({:emailerror => exception.message})
          else
            additionaldata = {:emailerror => exception.message}
          end
          self.update_attributes({:send_error => true, :additionaldata => additionaldata})            
          return false
        end
      end
      self.update_attributes({:sent_email => true, :sent_email_at => Time.now})
      return true
    end
  end
  
  def notifytype_to_s
    if(self.notifytype == NONE)
      return 'none'
    elsif(self.notifytype >= NOTIFICATION_PEOPLE[0] and self.notifytype <= NOTIFICATION_PEOPLE[1])
      return 'people'
    elsif(self.notifytype >= NOTIFICATION_AAE_INTERNAL[0] and self.notifytype <= NOTIFICATION_AAE_INTERNAL[1])
      return 'aae_internal'
    elsif(self.notifytype >= NOTIFICATION_AAE_PUBLIC[0] and self.notifytype <= NOTIFICATION_AAE_PUBLIC[1])
      return 'aae_public'
    else
      return nil
    end
  end
  
  def send_now?
    if(self.send_on_create?)
      self.send_email
    end
  end
  
  def createnotification?
    case self.notifytype
    when COMMUNITY_USER_NOINTEREST
      return false
    when NONE
      return false
    else
      return true
    end
  end
    
  def self.translate_connection_to_code(connectaction,connectiontype=nil)
    case connectaction
    when 'removeleader'
      COMMUNITY_LEADER_REMOVELEADER
    when 'removemember'
      COMMUNITY_LEADER_REMOVEMEMBER
    when 'addmember'
      COMMUNITY_LEADER_ADDMEMBER
    when 'addleader'
      COMMUNITY_LEADER_ADDLEADER
    when 'rescindinvitation'
      COMMUNITY_LEADER_RESCINDINVITATION
    when 'inviteleader'
      COMMUNITY_LEADER_INVITELEADER
    when 'invitemember'  
      COMMUNITY_LEADER_INVITEMEMBER
    when 'leave'
      COMMUNITY_USER_LEFT
    when 'join'
      COMMUNITY_USER_JOIN
    when 'nowantstojoin'
      COMMUNITY_USER_NOWANTSTOJOIN
    when 'wantstojoin'
      COMMUNITY_USER_WANTSTOJOIN
    when 'interest'
      COMMUNITY_USER_INTEREST
    when 'nointerest'
      COMMUNITY_USER_NOINTEREST
    when 'accept'
      COMMUNITY_USER_ACCEPT_INVITATION
    when 'decline'
      COMMUNITY_USER_DECLINE_INVITATION
    else
      NONE
    end
  end
  
  def self.clearerrors
    errors = find(:all, :conditions => {:send_error => true})
    errors.each do |notification|
      notification.update_attributes({:send_error => false})
    end
  end
  
  def self.userevent(notificationcode,user,community)
    case notificationcode
    when COMMUNITY_LEADER_ADDMEMBER
      userevent = "added #{user.login} to #{community.name} membership"
    when COMMUNITY_LEADER_ADDLEADER
      userevent = "added #{user.login} to #{community.name} leadership"
    when COMMUNITY_LEADER_REMOVEMEMBER
      userevent = "removed #{user.login} from #{community.name} membership"
    when COMMUNITY_LEADER_REMOVELEADER
      userevent = "removed #{user.login} from #{community.name} leadership"
    when COMMUNITY_LEADER_INVITELEADER
      userevent = "invited #{user.login} to #{community.name} leadership"
    when COMMUNITY_LEADER_INVITEMEMBER
      userevent = "invited #{user.login} to #{community.name} membership"
    when COMMUNITY_LEADER_INVITEREMINDER
      userevent = "sent an invitation reminder to #{user.login} for the #{community.name} community "      
    when COMMUNITY_LEADER_RESCINDINVITATION
      userevent = "rescinded invitation for #{user.login} to #{community.name}"
    when COMMUNITY_USER_LEFT
      userevent = "left #{community.name}"
    when COMMUNITY_USER_WANTSTOJOIN
      userevent = "wants to join #{community.name}"
    when COMMUNITY_USER_NOWANTSTOJOIN
      userevent = "no longer wants to join #{community.name}"
    when COMMUNITY_USER_INTEREST
      userevent = "interested in #{community.name}"
    when COMMUNITY_USER_NOINTEREST
      userevent = "no longer interested in #{community.name}"
    when COMMUNITY_USER_JOIN
      userevent = "joined #{community.name}"
    when COMMUNITY_USER_ACCEPT_INVITATION
      userevent = "accepted invitation to #{community.name}"
    when COMMUNITY_USER_ACCEPT_INVITATION
      userevent = "declined invitation to #{community.name}"
    else
      userevent = "Unknown Event"
    end
    return userevent
  end
   
  def self.showuserevent(notificationcode,showuser,byuser,community)
    case notificationcode
    when COMMUNITY_LEADER_ADDMEMBER
      showuserevent = "added to #{community.name} membership by #{byuser.login}"
    when COMMUNITY_LEADER_ADDLEADER
      showuserevent = "added to #{community.name} leadership by #{byuser.login}"
    when COMMUNITY_LEADER_REMOVEMEMBER
      showuserevent = "removed from #{community.name} membership by #{byuser.login}"
    when COMMUNITY_LEADER_REMOVELEADER
      showuserevent = "removed from #{community.name} leadership by #{byuser.login}"
    when COMMUNITY_LEADER_INVITELEADER
      showuserevent = "invited to #{community.name} leadership by #{byuser.login}"
    when COMMUNITY_LEADER_INVITEREMINDER
      showuserevent = "reminded of #{community.name} invitation by #{byuser.login}"
    when COMMUNITY_LEADER_INVITEMEMBER
      showuserevent = "invited to #{community.name} membership by #{byuser.login}"
    when COMMUNITY_LEADER_RESCINDINVITATION
      showuserevent = "invitation to #{community.name} rescinded by #{byuser.login}"
    else
      showuserevent = "Unknown event."
    end
    return showuserevent
  end
  

  
  
end