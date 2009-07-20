# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class NotificationMailer < ActionMailer::Base
  include ActionController::UrlWriter
  default_url_options[:host] = AppConfig.configtable['url_options']['host']
  default_url_options[:protocol] = AppConfig.configtable['url_options']['protocol']
  default_url_options[:port] = AppConfig.get_url_port


  def base_email(notification)
    @sent_on  = Time.now
    if(AppConfig.configtable['mail_label'] == 'production')
      @isdemo = false
      @subjectlabel = "eXtension Initiative: "
    else
      @isdemo = true
      @subjectlabel = "eXtension Initiative (#{AppConfig.configtable['mail_label']}): "
    end
    
    # set up the reply, bcc, and from name based on the notification type
    emailsettings_label = notification.notifytype_to_s
    if(emailsettings_label.nil? or emailsettings_label == 'none')
      emailsettings_label = 'default'
    end
    
    @from           = %("#{AppConfig.configtable['emailsettings'][emailsettings_label]['name']}" <#{AppConfig.configtable['emailsettings'][emailsettings_label]['address']}>)
    if(!AppConfig.configtable['emailsettings'][emailsettings_label]['bcc'].blank?)
      @bcc            = AppConfig.configtable['emailsettings'][emailsettings_label]['bcc']
    end
    @headers        = {}    
  end
  
  
  # -----------------------------------
  #  Emails sent to community leaders
  # -----------------------------------

  def community_user(notification)
    community = notification.community
    bycolleague = notification.user

    # base parameters for the email
    self.base_email(notification)
    @recipients     = community.notifyleaders.map(&:email).join(',')
    
    # special case for no recipients
    if(@recipients.nil? or @recipients == '')
      @recipients = AppConfig.configtable['emailsettings']['people']['bcc']
    end
    
    case notification.notifytype
    when Notification::COMMUNITY_USER_LEFT
      subjectaction = 'Left Community Notification'
      actionstring = 'has indicated in our people application that they are no longer interested in the community.'
    when Notification::COMMUNITY_USER_WANTSTOJOIN
      subjectaction = 'Wants to Join Community Notification'
      actionstring = 'has indicated in our people application that they want to join the community.'
    when Notification::COMMUNITY_USER_NOWANTSTOJOIN
      subjectaction = 'No Longer Wants to Join Community Notification'
      actionstring = 'has indicated in our people application that they no longer want to join the community.'
    when Notification::COMMUNITY_USER_JOIN
      subjectaction = 'Join Community Notification'
      actionstring = 'has indicated in our people application that they have joined the community.'
    when Notification::COMMUNITY_USER_INTEREST
      subjectaction = 'Community Interest Notification'
      actionstring = 'has indicated in our people application that they are interested in the community.' 
    when Notification::COMMUNITY_USER_NOINTEREST
      subjectaction = 'No Longer Interested In Community Notification'
      actionstring = 'has indicated in our people application that they no longer interested in the community.'     
    when Notification::COMMUNITY_USER_ACCEPT_INVITATION
      subjectaction = 'Accepted Invitation to Community Notification'
      actionstring = 'has accepted the invitation to join the community.'
    when Notification::COMMUNITY_USER_DECLINE_INVITATION
      subjectaction = 'Declined Invitation to Community Notification'
      actionstring = 'has declined the invitation to join the community.'
    else 
      subjectaction = 'Unknown Community Notification'
      actionstring = 'has triggered an unknown condition inside the people application.'
      @recipients = 'systems@extension.org'
    end
    
    urls = Hash.new
    urls['showcolleague'] = url_for(:controller => :colleagues, :action => :showuser, :id => bycolleague.login)
    urls['contactus'] = url_for(:controller => :help, :action => :contactform)
    urls['showcommunity'] = url_for(:controller => :communities, :action => :show, :id => community.id)


    @subject        = @subjectlabel+subjectaction
    @body           = {:isdemo => @isdemo, :community => community, :bycolleague => bycolleague, :urls => urls,:actionstring => actionstring}
  end
  
  def community_change_notifygroup(notification)
    # setting variables for backwards compatibility
    community = notification.community
    bycolleague = notification.creator
    oncolleague = notification.user
    
    # base parameters for the email
    self.base_email(notification)
    @recipients     = community.notifyleaders.map(&:email).join(',')
    
    # special case for no recipients
    if(@recipients.nil? or @recipients == '')
      @recipients = AppConfig.configtable['emailsettings']['people']['bcc']
    end
    
    case notification.notifytype
    when Notification::COMMUNITY_LEADER_REMOVELEADER
      subjectaction = 'Community Leadership Change'
      actionstring = '%s has been removed from the Community Leadership.'
    when Notification::COMMUNITY_LEADER_ADDLEADER
      subjectaction = 'Community Leadership Change'
      actionstring = '%s has been added to the Community Leadership.'
    when Notification::COMMUNITY_LEADER_REMOVEMEMBER
      subjectaction = 'Community Membership Change'
      actionstring = '%s has been removed from the Community Membership.'
    when Notification::COMMUNITY_LEADER_ADDMEMBER
      subjectaction = 'Community Membership Change'
      actionstring = '%s has been added to the Community Membership.'
    when Notification::COMMUNITY_LEADER_INVITELEADER
      subjectaction = 'Community Invitation'
      actionstring = '%s has been invited to the Community as a Leader.'
    when Notification::COMMUNITY_LEADER_INVITEMEMBER
      subjectaction = 'Community Invitation'
      actionstring = '%s has been invited to the Community as a Member.'
    when Notification::COMMUNITY_LEADER_INVITEREMINDER
      subjectaction = 'Community Invitation Reminder'
      actionstring = '%s has been sent a reminder about their invitation to the Community.'   
    when Notification::COMMUNITY_LEADER_RESCINDINVITATION
      subjectaction = 'Community Invitation Change'
      actionstring = 'The invitation for %s to the Community has been rescinded.'
    else 
      subjectaction = 'Unknown Community Notification'
      actionstring = 'has triggered an unknown condition inside the people application.'
      @recipients = 'systems@extension.org'
    end  
    
    urls = Hash.new
    urls['bycolleague'] = url_for(:controller => :colleagues, :action => :showuser, :id => bycolleague.login)
    urls['oncolleague'] = url_for(:controller => :colleagues, :action => :showuser, :id => oncolleague.login)
    urls['contactus'] = url_for(:controller => :help, :action => :contactform)
    urls['showcommunity'] = url_for(:controller => :communities, :action => :show, :id => community.id)


    @subject        = @subjectlabel+subjectaction
    @body           = {:isdemo => @isdemo, :community => community, :bycolleague => bycolleague, :oncolleague => oncolleague, :urls => urls, :actionstring => actionstring}
  end  



  # -----------------------------------
  #  Emails sent to users
  # -----------------------------------

  def community_change_notifyuser(notification)
    # setting variables for backwards compatibility
    community = notification.community
    bycolleague = notification.creator
    oncolleague = notification.user

    # base parameters for the email
    self.base_email(notification)
    @recipients     = oncolleague.email
    # don't cc systemuser
    if(!bycolleague.is_systemuser?)
      @cc             = bycolleague.email
    end
    
    # default
    responsestring = "You can see more information about the #{community.name} community at:"
      
    case notification.notifytype
    when Notification::COMMUNITY_LEADER_REMOVELEADER
      subjectaction = 'Removed from Community Leadership'
      actionstring = "You have been removed from the leadership in the #{community.name} community"
    when Notification::COMMUNITY_LEADER_ADDLEADER
      subjectaction = 'Added to Community Leadership'
      actionstring = "You have been added to the leadership in the #{community.name} community"
    when Notification::COMMUNITY_LEADER_REMOVEMEMBER
      subjectaction = 'Removed from Community Membership'
      actionstring = "You have been removed from the membership in the #{community.name} community"
    when Notification::COMMUNITY_LEADER_ADDMEMBER
      subjectaction = 'Added to Community Membership'
      actionstring = "You have been added to the membership in the #{community.name} community"
    when Notification::COMMUNITY_LEADER_INVITELEADER
      subjectaction = 'Invited to Community Leadership'
      actionstring = "You have been invited to join the #{community.name} community as a leader"      
      responsestring = "You will need to Accept or Decline this invitation to join the community by visiting:"
    when Notification::COMMUNITY_LEADER_INVITEMEMBER
      subjectaction = 'Invited to Community Membership'
      actionstring = "You have been invited to join the #{community.name} community as a member"
      responsestring = "You will need to Accept or Decline this invitation to join the community by visiting:"
    when Notification::COMMUNITY_LEADER_INVITEREMINDER
      subjectaction = 'Invited to Community'
      actionstring = "Just a reminder - you have been invited to join the #{community.name} community"      
      responsestring = "You will need to Accept or Decline this invitation to join the community by visiting:"
    when Notification::COMMUNITY_LEADER_RESCINDINVITATION
      subjectaction = 'Invitation to Community Rescinded'
      actionstring = "Your invitation to join the #{community.name} community has been rescinded"      
    else 
      subjectaction = 'Unknown Community Notification'
      actionstring = 'An unknown condition inside the people application has been triggered'
      @recipients = 'systems@extension.org'
      @cc = nil
    end  
    
    urls = Hash.new
    urls['bycolleague'] = url_for(:controller => :colleagues, :action => :showuser, :id => bycolleague.login)
    urls['contactus'] = url_for(:controller => :help, :action => :contactform)
    urls['showcommunity'] = url_for(:controller => :communities, :action => :show, :id => community.id)


    @subject        = @subjectlabel+subjectaction
    @body           = {:isdemo => @isdemo, :community => community, :bycolleague => bycolleague, :oncolleague => oncolleague, :urls => urls, :actionstring => actionstring, :responsestring => responsestring}
  end
    
  # -----------------------------------
  #  eXtensionID Invitation
  # -----------------------------------
  
  def invitation_to_extensionid(notification)
    
    # base parameters for the email
    self.base_email
    @recipients     = notification.additionaldata[:invitation_email]
    @cc             = notification.user.email
    @subject        = @subjectlabel+'You have been invited to get an eXtensionID'
    
    urls = Hash.new
    urls['signup'] = url_for(:controller => 'signup', :action => 'new', :invite => notification.additionaldata[:invitation_token])
    urls['contactus'] = url_for(:controller => 'help', :action => 'contactform')
    @body           = {:isdemo => @isdemo, :notification => notification, :urls => urls }  
  end
  
  def accepted_extensionid_invitation(notification)
    # base parameters for the email
    self.base_email
    @recipients     = notification.user.email
    @subject        = @subjectlabel+'Accepted eXtensionID Notification'
    
    urls = Hash.new
    urls['showcolleague'] = url_for(:controller => :colleagues, :action => :showuser, :id => notification.creator.login)
    urls['contactus'] = url_for(:controller => 'help', :action => 'contactform')
    @body           = {:isdemo => @isdemo, :notification => notification, :urls => urls }  
  end
  
  # -----------------------------------
  #  email/signup confirmation
  # -----------------------------------
  
  def confirm_email(notification,token)
     # base parameters for the email
     self.base_email(notification)
     @recipients     = token.user.email
     @subject        = @subjectlabel+'Please confirm your email address'
     urls = Hash.new
     urls['directurl'] = url_for(:controller => :account, :action => :confirmemail, :token => token.token)
     urls['manualurl'] = url_for(:controller => :account, :action => :confirmemail)        
     urls['newtoken'] = url_for(:controller => :account, :action => :confirmemail, :token => 'send')        
     urls['contactus'] = url_for(:controller => :help, :action => :contactform)
     @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
   end
   
   def reconfirm_email(notification,token)
      # base parameters for the email
      self.base_email(notification)
      @recipients     = token.user.email
      @subject        = @subjectlabel+'Please confirm your email address'
      urls = Hash.new
      urls['home'] = url_for(welcome_url)
      urls['directurl'] = url_for(:controller => :account, :action => :confirmemail, :token => token.token)
      urls['manualurl'] = url_for(:controller => :account, :action => :confirmemail)        
      urls['newtoken'] = url_for(:controller => :account, :action => :confirmemail, :token => 'send')        
      urls['contactus'] = url_for(:controller => :help, :action => :contactform)
      @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
   end
  
   def reconfirm_signup(notification,token)
      # base parameters for the email
      self.base_email(notification)
      @recipients     = token.user.email
      @subject        = @subjectlabel+'Please confirm your email address'
      urls = Hash.new
      urls['home'] = url_for(welcome_url)
      urls['directurl'] = url_for(:controller => :signup, :action => :confirm, :token => token.token)
      urls['manualurl'] = url_for(:controller => :signup, :action => :confirm)        
      urls['newtoken'] = url_for(:controller => :signup, :action => :confirm, :token => 'send')        
      urls['contactus'] = url_for(:controller => :help, :action => :contactform)
      @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
   end
   
   
   # -----------------------------------
   #  Ask an Expert
   # -----------------------------------
   
   def assigned(notification,submitted_question)
     # base parameters for the email
     self.base_email(notification)     
     @subject        = @subjectlabel+'Incoming question assigned to you'
     @recipients     = notification.user.email
     assigned_at = @sent_on
     respond_by = assigned_at +  48.hours
     urls = Hash.new
     urls['question'] = url_for(:controller => 'ask/expert', :action => 'question', :id => submitted_question.id)
     # TODO: fix contact us URL
     urls['contactus'] = url_for(:controller => '/')
     @body           = {:isdemo => @isdemo, :submitted_question => submitted_question, :assigned_at => assigned_at, :respond_by => respond_by, :urls => urls }
   end
 
   def reassigned(notification,submitted_question)
     # base parameters for the email
     self.base_email(notification)     
     @subject        = @subjectlabel+'Incoming question reassigned'
     @recipients     = notification.user.email
     assigned_at = @sent_on
     urls = Hash.new
     urls['question'] = url_for(:controller => 'ask/expert', :action => 'question', :id => submitted_question.id)
     # TODO: fix contact us URL
     urls['contactus'] = url_for(:controller => '/')
     @body           = {:isdemo => @isdemo, :submitted_question => submitted_question, :assigned_at => assigned_at, :urls => urls }
   end

   def escalation(recipients, submitted_questions, report_url, host = 'faq.extension.org', sent_at = Time.now)
     @subject = host.to_s + ': Ask an Expert Escalation Report'
     @body["submitted_questions"] = submitted_questions
     @body["report_url"] = report_url
     @body["host"] = host
     @recipients = recipients
     @from = "noreplies@extension.org"
     @sent_on = sent_at
     if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
       @bcc            = AppConfig.configtable['mail_system_bcc']
     end
     @headers = {}
   end



   def response_email(emailVar, expert_question, external_name, url_var, signature)
     @subject = "[Message from eXtension] Your question has been answered by one of our experts."
     @body["answer"] = expert_question.current_response
     @body["question"] = expert_question.asked_question
     @body["external_name"] = external_name
     @body["url_var"] = url_var
     @body["signature"] = signature
     @body["disclaimer"] = SubmittedQuestion::EXPERT_DISCLAIMER
     @recipients = emailVar
     @from = 'noreplies@extension.org'
     @headers["Organization"] = "eXtension Initiative"

     if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
       @bcc            = AppConfig.configtable['mail_system_bcc']
     end
   end
   
   
end