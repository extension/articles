#!/usr/bin/env ruby
#TODO: refactor this script
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--limit","-l", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@limit = 10

progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--limit'
      @limit = arg
    else
      puts "Unrecognized option #{opt}"
      exit 0
    end
end
### END Program Options

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = @environment
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

def notify_of_action_byuser(notification)
  puts "Notifying Community Leaders of a user action..."
  
  # send an email to the community leaders
  leaderemail = NotificationMailer.create_community_user(notification)
  begin 
    NotificationMailer.deliver(leaderemail)
  rescue
    puts "ERROR: Unable to deliver community leader email."
    return false
  end
  
  return true
end

def notify_of_action_byleader(notification)
  puts "Notifying Community Leaders and the user of a leader action..."
  
  leaderemail = NotificationMailer.create_community_change_notifygroup(notification)
  useremail = NotificationMailer.create_community_change_notifyuser(notification)
 
  begin 
    NotificationMailer.deliver(leaderemail)
  rescue
    puts "ERROR: Unable to deliver community leader email."
    return false
  end 

  begin 
    NotificationMailer.deliver(useremail)
  rescue
    puts "ERROR: Unable to deliver community user email."
    return false
  end

  return true
end

def notify_invitation(notification)
  puts "Sending eXtensionID Invitation Notification..."

  invitiationemail = NotificationMailer.create_invitation_to_extensionid(notification)
 
  begin 
    NotificationMailer.deliver(invitiationemail)
  rescue
    puts "ERROR: Unable to deliver eXtensionID Invitation email."
    return false
  end 

  return true
end

def notify_invitation_accepted(notification)
  puts "Sending eXtensionID Accepted Invitation Notification..."

  acceptedinvitiationemail = NotificationMailer.create_accepted_extensionid_invitation(notification)
 
  begin 
    NotificationMailer.deliver(acceptedinvitiationemail)
  rescue
    puts "ERROR: Unable to deliver eXtensionID Accepted Invitation email."
    return false
  end 

  return true
end

def notify_emailconfirmation(notification)
  puts "Sending email confirmation..."

  emailconfirmation = NotificationMailer.create_confirm_email(notification,UserToken.find(notification.additionaldata[:token_id]))
 
  begin 
    NotificationMailer.deliver(emailconfirmation)
  rescue
    puts "ERROR: Unable to deliver email confirmation."
    return false
  end 

  return true
end

def notify_emailreconfirmation(notification)
  puts "Sending email re-confirmation..."

  emailreconfirmation = NotificationMailer.create_reconfirm_email(notification,UserToken.find(notification.additionaldata[:token_id]))
 
  begin 
    NotificationMailer.deliver(emailreconfirmation)
  rescue
    puts "ERROR: Unable to deliver email reconfirmation."
    return false
  end 

  return true
end

def notify_signupreconfirmation(notification)
  puts "Sending signup re-confirmation..."

  email = NotificationMailer.create_reconfirm_signup(notification,UserToken.find(notification.additionaldata[:token_id]))
 
  begin 
    NotificationMailer.deliver(email)
  rescue
    puts "ERROR: Unable to deliver signup reconfirmation."
    return false
  end 

  return true
end


def notify_aae_assignment(notification)
  puts "Sending aae assignment notification..."
  email = NotificationMailer.create_aae_assigned(notification)
  begin 
    NotificationMailer.deliver(email)
  rescue
    puts "ERROR: Unable to deliver aae assignment notification."
    return false
  end 
  return true
end

def notify_aae_reassignment(notification)
  puts "Sending aae reassignment notification..."
  email = NotificationMailer.create_aae_reassigned(notification)
  begin 
    NotificationMailer.deliver(email)
  rescue
    puts "ERROR: Unable to deliver aae reassignment notification."
    return false
  end 
  return true
end

def notify_aae_public_response(notification)
  puts "Sending aae response to public..."
  email = NotificationMailer.create_aae_public_response(notification)
  begin 
    NotificationMailer.deliver(email)
  rescue
    puts "ERROR: Unable to deliver aae response to public."
    return false
  end 
  return true
end

def notify_aae_public_submission(notification)
  puts "Sending aae submission notification to public..."
  email = NotificationMailer.create_aae_public_submission(notification)
  begin 
    NotificationMailer.deliver(email)
  rescue
    puts "ERROR: Unable to deliver aae submission notification."
    return false
  end 
  return true
end

# main
notifications = Notification.tosend.find(:all, :limit => @limit)
@notificationcount = notifications.size
if (notifications.nil? or notifications.empty?)
  puts "No notifications to processs"
end

@successcount = 0
@failurecount = 0

notifications.each do |notification|

  case notification.notifytype
  when Notification::COMMUNITY_USER_JOIN
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_USER_LEFT
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_USER_WANTSTOJOIN
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_USER_NOWANTSTOJOIN
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_USER_INTEREST
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_USER_NOINTEREST
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_USER_ACCEPT_INVITATION
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_USER_DECLINE_INVITATION
    notificationresult = notify_of_action_byuser(notification)
  when Notification::COMMUNITY_LEADER_INVITELEADER
    notificationresult = notify_of_action_byleader(notification)
  when Notification::COMMUNITY_LEADER_INVITEMEMBER
    notificationresult = notify_of_action_byleader(notification)
  when Notification::COMMUNITY_LEADER_INVITEREMINDER
    notificationresult = notify_of_action_byleader(notification)
  when Notification::COMMUNITY_LEADER_ADDLEADER
    notificationresult = notify_of_action_byleader(notification)
  when Notification::COMMUNITY_LEADER_ADDMEMBER
    notificationresult = notify_of_action_byleader(notification)
  when Notification::COMMUNITY_LEADER_REMOVELEADER
    notificationresult = notify_of_action_byleader(notification)
  when Notification::COMMUNITY_LEADER_REMOVEMEMBER
    notificationresult = notify_of_action_byleader(notification)
  when Notification::COMMUNITY_LEADER_RESCINDINVITATION
    notificationresult = notify_of_action_byleader(notification)
  when Notification::INVITATION_TO_EXTENSIONID
    notificationresult = notify_invitation(notification)
  when Notification::INVITATION_ACCEPTED
    notificationresult = notify_invitation_accepted(notification)
  when Notification::CONFIRM_EMAIL
    notificationresult = notify_emailconfirmation(notification)
  when Notification::RECONFIRM_EMAIL
    notificationresult = notify_emailreconfirmation(notification)
  when Notification::RECONFIRM_SIGNUP
    notificationresult = notify_signupreconfirmation(notification)
  when Notification::AAE_ASSIGNMENT
    notificationresult = notify_aae_assignment(notification)
  when Notification::AAE_REASSIGNMENT
    notificationresult = notify_aae_reassignment(notification)  
  when Notification::AAE_PUBLIC_EXPERT_RESPONSE
    notificationresult = notify_aae_public_response(notification)    
  when Notification::AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT
    notificationresult = notify_aae_public_submission(notification)    
  else
    # nothing
  end
  
  if(notificationresult)
    puts "Success!"
    @successcount += 1;
    notification.update_attributes({:sent_email => true, :sent_email_at => Time.now})
  else
    puts "Fail!"
    @failurecount += 1;
    notification.update_attributes({:send_error => true})  
  end
  
end

# log
if(@notificationcount > 0)
  AdminEvent.log_data_event(AdminEvent::SENT_NOTIFICATIONS, {:notificationcount => @notificationcount, :successcount => @successcount, :failurecount => @failurecount})
end
