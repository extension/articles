# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class NotificationMailer < ActionMailer::Base
  include ActionController::UrlWriter
  default_url_options[:host] = AppConfig.get_url_host
  default_url_options[:protocol] = AppConfig.get_url_protocol
  if(default_port = AppConfig.get_url_port)
    default_url_options[:port] = default_port
  end
      
  def base_email(emailsettings_label = 'default', from_name = nil)
    @sent_on  = Time.now
    if(AppConfig.configtable['app_location'] == 'production')
      @isdemo = false
      @subjectlabel = "eXtension Initiative: "
    else
      @isdemo = true
      @subjectlabel = "eXtension Initiative (#{AppConfig.configtable['app_location']}): "
    end
    
    # set up the reply, bcc, and from name based on the notification type
    if(emailsettings_label.nil? or emailsettings_label == 'none')
      emailsettings_label = 'default'
    end
    
    # setup the name for the :from address, widgets can now have custom :from names for AaE correspondance 
    from_name = AppConfig.configtable['emailsettings'][emailsettings_label]['name'] if from_name.nil? 
    
    @from           = %("#{from_name}" <#{AppConfig.configtable['emailsettings'][emailsettings_label]['address']}>)
    if(!AppConfig.configtable['emailsettings'][emailsettings_label]['bcc'].blank?)
      @bcc            = AppConfig.configtable['emailsettings'][emailsettings_label]['bcc']
    end
    @headers        = {}
    @headers["Organization"] = "eXtension Initiative"    
  end  
  
  # -----------------------------------
  #  Emails sent to community leaders
  # -----------------------------------

  def community_user(notification)
    community = notification.community
    bycolleague = notification.user

    # base parameters for the email
    self.base_email(notification.notifytype_to_s)
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
    urls['showcolleague'] = url_for(:controller => '/people/colleagues', :action => :showuser, :id => bycolleague.login)
    urls['contactus'] = people_contact_url
    urls['showcommunity'] = url_for(:controller => '/people/communities', :action => :show, :id => community.id)


    @subject        = @subjectlabel+subjectaction
    @body           = {:isdemo => @isdemo, :community => community, :bycolleague => bycolleague, :urls => urls,:actionstring => actionstring}
  end
  
  def community_change_notifygroup(notification)
    # setting variables for backwards compatibility
    community = notification.community
    bycolleague = notification.creator
    oncolleague = notification.user
    
    # base parameters for the email
    self.base_email(notification.notifytype_to_s)
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
    urls['bycolleague'] = url_for(:controller => '/people/colleagues', :action => :showuser, :id => bycolleague.login)
    urls['oncolleague'] = url_for(:controller => '/people/colleagues', :action => :showuser, :id => oncolleague.login)
    urls['contactus'] = people_contact_url
    urls['showcommunity'] = url_for(:controller => '/people/communities', :action => :show, :id => community.id)


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
    self.base_email(notification.notifytype_to_s)
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
    urls['bycolleague'] = url_for(:controller => '/people/colleagues', :action => :showuser, :id => bycolleague.login)
    urls['contactus'] = people_contact_url
    urls['showcommunity'] = url_for(:controller => '/people/communities', :action => :show, :id => community.id)


    @subject        = @subjectlabel+subjectaction
    @body           = {:isdemo => @isdemo, :community => community, :bycolleague => bycolleague, :oncolleague => oncolleague, :urls => urls, :actionstring => actionstring, :responsestring => responsestring}
  end
    
  # -----------------------------------
  #  eXtensionID Invitation
  # -----------------------------------
  
  def invitation_to_extensionid(notification)
    # base parameters for the email
    self.base_email(notification.notifytype_to_s)
    @recipients     = notification.additionaldata[:invitation_email]
    @cc             = notification.user.email
    @subject        = @subjectlabel+'You have been invited to get an eXtensionID'
    
    urls = Hash.new
    urls['signup'] = url_for(:controller => '/people/signup', :action => 'readme', :invite => notification.additionaldata[:invitation_token])
    urls['contactus'] = people_contact_url
    @body           = {:isdemo => @isdemo, :notification => notification, :urls => urls }  
  end
  
  def accepted_extensionid_invitation(notification)
    # base parameters for the email
    self.base_email(notification.notifytype_to_s)
    @recipients     = notification.user.email
    @subject        = @subjectlabel+'Accepted eXtensionID Notification'
    
    urls = Hash.new
    urls['showcolleague'] = url_for(:controller => '/people/colleagues', :action => :showuser, :id => notification.creator.login)
    urls['contactus'] = people_contact_url
    @body           = {:isdemo => @isdemo, :notification => notification, :urls => urls }  
  end
  
  # -----------------------------------
  #  email/signup confirmation
  # -----------------------------------
  
  def confirm_email_change(notification)
    # base parameters for the email
    self.base_email(notification.notifytype_to_s)
    token = UserToken.find(notification.additionaldata[:token_id])
    @recipients     = token.user.email
    @subject        = @subjectlabel+'Please confirm your email address'
    urls = Hash.new
    urls['directurl'] = url_for(:controller => 'people/account', :action => :confirmemail, :token => token.token)
    urls['manualurl'] = url_for(:controller => 'people/account', :action => :confirmemail)        
    urls['newtoken'] = url_for(:controller => 'people/account', :action => :confirmemail, :token => 'send')        
    urls['contactus'] = people_contact_url
    @body           = {:isdemo => @isdemo, :token => token, :urls => urls }
  end
  
  def confirm_email(notification)
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)
     token = UserToken.find(notification.additionaldata[:token_id])
     @recipients     = token.user.email
     @subject        = @subjectlabel+'Please confirm your email address'
     urls = Hash.new
     urls['directurl'] = url_for(:controller => '/people/account', :action => :confirmemail, :token => token.token)
     urls['manualurl'] = url_for(:controller => '/people/account', :action => :confirmemail)        
     urls['newtoken'] = url_for(:controller => '/people/account', :action => :confirmemail, :token => 'send')        
     urls['contactus'] = people_contact_url
     @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
   end
   
   def reconfirm_email(notification)
      # base parameters for the email
      self.base_email(notification.notifytype_to_s)
      token = UserToken.find(notification.additionaldata[:token_id])
      @recipients     = token.user.email
      @subject        = @subjectlabel+'Please confirm your email address'
      urls = Hash.new
      urls['home'] = url_for(people_welcome_url)
      urls['directurl'] = url_for(:controller => '/people/account', :action => :confirmemail, :token => token.token)
      urls['manualurl'] = url_for(:controller => '/people/account', :action => :confirmemail)        
      urls['newtoken'] = url_for(:controller => '/people/account', :action => :confirmemail, :token => 'send')        
      urls['contactus'] = people_contact_url
      @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
   end
   
   def confirm_signup(notification)
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)
     token = UserToken.find(notification.additionaldata[:token_id])
     @recipients     = token.user.email
     @subject        = @subjectlabel+'Please confirm your email address'
     urls = Hash.new
     urls['directurl'] = url_for(:controller => 'people/signup', :action => :confirm, :token => token.token)
     urls['manualurl'] = url_for(:controller => 'people/signup', :action => :confirm)        
     urls['newtoken'] = url_for(:controller => 'people/signup', :action => :confirmemail, :token => 'send')        
     urls['contactus'] = people_contact_url    
     @body           = {:isdemo => @isdemo, :token => token, :urls => urls,:additionaloptions => notification.additionaldata}  
   end
  
   def reconfirm_signup(notification)
      # base parameters for the email
      self.base_email(notification.notifytype_to_s)
      token = UserToken.find(notification.additionaldata[:token_id])
      @recipients     = token.user.email
      @subject        = @subjectlabel+'Please confirm your email address'
      urls = Hash.new
      urls['home'] = url_for(people_welcome_url)
      urls['directurl'] = url_for(:controller => '/people/signup', :action => :confirm, :token => token.token)
      urls['manualurl'] = url_for(:controller => '/people/signup', :action => :confirm)        
      urls['newtoken'] = url_for(:controller => '/people/signup', :action => :confirm, :token => 'send')        
      urls['contactus'] = people_contact_url
      @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
   end
   
   def welcome(notification)
     self.base_email(notification.notifytype_to_s)
     @recipients     = notification.user.email
     @subject        = @subjectlabel+'Welcome!'
     urls = Hash.new
     urls['profile'] = url_for(:controller => 'people/profile', :action => 'me')
     urls['contactus'] = people_contact_url
     @body           = {:isdemo => @isdemo, :user => notification.user, :urls => urls }  
   end
   
   
   # -----------------------------------
   #  review
   # -----------------------------------
   
   def review_request(notification)
     self.base_email(notification.notifytype_to_s)      
     reviewuser = notification.user
     @from           = "\"#{reviewuser.first_name} #{reviewuser.last_name}\" <#{reviewuser.email}>"
     @recipients     = AppConfig.configtable['emailsettings']['people']['review']
     @subject        = @subjectlabel+'Account Review Request'    
     urls = Hash.new
     urls['reviewurl'] = url_for(:controller => 'people/colleagues', :action => 'showuser', :id => reviewuser.login)
     urls['contactus'] = people_contact_url
     @body           = {:isdemo => @isdemo, :reviewuser => reviewuser, :urls => urls }  
   end
   
   
   # -----------------------------------
   #  passwords
   # -----------------------------------
   
   def confirm_password(notification)
      # base parameters for the email
      self.base_email(notification.notifytype_to_s)
      token = UserToken.find(notification.additionaldata[:token_id])
      @recipients     = token.user.email
      @subject        = @subjectlabel+'Please confirm your email address'
      urls = Hash.new
      urls['directurl'] = url_for(:controller => '/people/account', :action => :set_password, :token => token.token)
      urls['manualurl'] = url_for(:controller => '/people/account', :action => :set_password)        
      urls['newtoken'] = url_for(:controller => '/people/account', :action => :new_password, :token => 'send')        
      urls['contactus'] = people_contact_url
      @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
    end



   
   # -----------------------------------
   #  Ask an Expert
   # -----------------------------------
   
   def aae_assigned(notification)
     submitted_question = SubmittedQuestion.find(notification.additionaldata[:submitted_question_id])
     assigner = User.find(notification.created_by)
     public_comment = notification.additionaldata[:asker_comment] if notification.additionaldata[:asker_comment]
     reassign_comment = notification.additionaldata[:comment] if notification.additionaldata[:comment]
     
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)     
     @subject        = @subjectlabel+'Incoming question assigned to you'
     @recipients     = notification.user.email
     assigned_at = @sent_on     
     respond_by = assigned_at +  (AppConfig.configtable['aae_escalation_delta']).hours
     urls = Hash.new
     urls['question'] = aae_question_url(:id => submitted_question.id)
     urls['contactus'] = url_for(:controller => 'aae/help', :action => :index)
     @body           = {:isdemo => @isdemo, :notification => notification, :submitted_question => submitted_question, :assigned_at => assigned_at, :respond_by => respond_by, :urls => urls, :assigner => assigner, :reassign_comment => reassign_comment, :public_comment => public_comment }
   end
   
   def aae_public_edit(notification)
     submitted_question = SubmittedQuestion.find(notification.additionaldata[:submitted_question_id])
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)     
     @subject        = @subjectlabel+'Incoming question edited by submitter'
     @recipients     = notification.user.email
     assigned_at = @sent_on     
     respond_by = assigned_at +  (AppConfig.configtable['aae_escalation_delta']).hours
     urls = Hash.new
     urls['question'] = aae_question_url(:id => submitted_question.id)
     urls['contactus'] = url_for(:controller => 'aae/help', :action => :index)
     @body           = {:isdemo => @isdemo, :notification => notification, :submitted_question => submitted_question, :assigned_at => assigned_at, :respond_by => respond_by, :urls => urls }
   end
 
   def aae_reassigned(notification)
     submitted_question = SubmittedQuestion.find(notification.additionaldata[:submitted_question_id])
     
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)     
     @subject        = @subjectlabel+'Incoming question reassigned'
     @recipients     = notification.user.email
     assigned_at = @sent_on
     urls = Hash.new
     urls['incoming'] = incoming_url
     urls['question'] = aae_question_url(:id => submitted_question.id)
     urls['contactus'] = url_for(:controller => 'aae/help', :action => :index)
     @body           = {:isdemo => @isdemo, :notification => notification, :submitted_question => submitted_question, :assigned_at => assigned_at, :urls => urls }
   end
   
   def aae_reject(notification)
     submitted_question = SubmittedQuestion.find(notification.additionaldata[:submitted_question_id])
     reject_message = notification.additionaldata[:reject_message]
     
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)
     @subject        = @subjectlabel+'Incoming question rejected'
     @recipients     = notification.user.email
     urls = Hash.new
     urls['incoming'] = incoming_url
     urls['question'] = aae_question_url(:id => submitted_question.id)
     urls['contactus'] = url_for(:controller => 'aae/help', :action => :index)
     @body           = {:isdemo => @isdemo, :notification => notification, :resolved_at => submitted_question.resolved_at, :reject_message => reject_message, :submitted_question => submitted_question, :urls => urls }
   end

   def aae_public_response(notification)
     submitted_question = SubmittedQuestion.find(notification.additionaldata[:submitted_question_id])
     signature = notification.additionaldata[:signature]
     # base parameters for the email
     self.base_email(notification.notifytype_to_s, submitted_question.get_custom_email_from)
     @subject = "[Message from eXtension] Your question has been responded to by one of our experts."           
     @recipients     = submitted_question.submitter_email
     urls = Hash.new
     urls['question'] = ask_question_url(:fingerprint => submitted_question.question_fingerprint)
     urls['askanexpert'] = ask_form_url
     @body           = {:isdemo => @isdemo, :notification => notification,  :signature => signature, :urls => urls }
   end
   
   def aae_public_submission(notification)
     submitted_question = SubmittedQuestion.find(notification.additionaldata[:submitted_question_id])
     # base parameters for the email
     self.base_email(notification.notifytype_to_s, submitted_question.get_custom_email_from)
     @subject = "[Message from eXtension] Thank you for your question submission."          
     @recipients     = submitted_question.public_user.email
     urls = Hash.new
     urls['question'] = ask_question_url(:fingerprint => submitted_question.question_fingerprint)
     @body           = {:isdemo => @isdemo, :notification => notification, :submitted_question => submitted_question, :urls => urls }
   end
   
   def aae_public_comment(notification)
     submitted_question = SubmittedQuestion.find(notification.additionaldata[:submitted_question_id])
     response = Response.find(notification.additionaldata[:response_id])
     assigned_at = submitted_question.assigned_date
     respond_by = assigned_at +  (AppConfig.configtable['aae_escalation_delta']).hours
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)
     @subject = "[Message from eXtension] A question you have been assigned has a new comment"          
     @recipients     = notification.user.email
     urls = Hash.new
     urls['question'] = aae_question_url(:id => submitted_question.id)
     urls['contactus'] = url_for(:controller => 'aae/help', :action => :index)
     @body           = {:isdemo => @isdemo, :notification => notification, :submitted_question => submitted_question, :respond_by => respond_by, :assigned_at => assigned_at, :response => response, :urls => urls}
   end
   
   
   ### NOTE: not based on a notification
   def aae_escalation_for_category(category, sincehours)
     # base parameters for the email
     self.base_email('aae_internal')     
     @subject        = @subjectlabel+'Ask an Expert Escalation Report'
     
       
     submitted_questions_list = SubmittedQuestion.escalated(sincehours).filtered({:category => category}).ordered('submitted_questions.last_opened_at asc')
     escalation_users_for_category = User.validusers.escalators_by_category(category)
     if(escalation_emails = User.validusers.escalators_by_category(category))
       @recipients = escalation_users_for_category.map(&:email).join(',')
     else
       # TODO: should this be the extension leadership? question wranglers?
       @recipients = AppConfig.configtable['emailsettings']['aae_internal']['bcc']
     end
     
     urls = Hash.new
     # TODO: must be fixed when escalation report is moved
     urls['escalation_report'] = url_for(:controller => 'aae/question', :action => 'escalation_report', :id => category.id)
     urls['contactus'] = url_for(:controller => 'aae/help', :action => :index)
     @body           = {:isdemo => @isdemo, :submitted_questions_list => submitted_questions_list, :sincehours => sincehours, :urls => urls }
   end
  
   # -----------------------------------
   #  learn session
   # -----------------------------------

   def learn_upcoming_session(notification)
     learn_session = LearnSession.find(notification.additionaldata[:learn_session_id])
     # base parameters for the email
     self.base_email(notification.notifytype_to_s)
     @subject        = @subjectlabel+'Upcoming Learn Session'
     @recipients     = notification.user.email
     urls = Hash.new
     urls['learnsession'] = url_for(:controller => 'learn', :action => :event, :id =>  learn_session.id)
     @body = {:isdemo => @isdemo, :notification => notification, :learn_session => learn_session, :urls => urls}
   end  
  
   # -----------------------------------
   #  system administration
   # -----------------------------------

   def deployment(deployinfo,scmoutput)
      # base parameters for the email
      self.base_email('deploy')
      @recipients     = 'dev-deploys@lists.extension.org'
      #override
      @bcc = nil
      @subject        = @subjectlabel+'Darmok deployment notification'
      @body           = {:isdemo => @isdemo, :deployinfo => deployinfo, :scmoutput => scmoutput}  
    end    
   
end