# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AccountMailer < ActionMailer::Base
  include ActionController::UrlWriter

  def self.set_url_options
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
      default_url_options[:port] = default_port
    end
  end
  
  def base_email
    AccountMailer.set_url_options
    @sent_on  = Time.now
    if(AppConfig.configtable['mail_label'] == 'production')
      @isdemo = false
      @subjectlabel = "eXtension Initiative: "
    else
      @isdemo = true
      @subjectlabel = "eXtension Initiative (#{AppConfig.configtable['mail_label']}): "
    end
    
    # set up the reply, bcc, and from name based on the notification type
    emailsettings_label = 'people'
    
    @from           = %("#{AppConfig.configtable['emailsettings'][emailsettings_label]['name']}" <#{AppConfig.configtable['emailsettings'][emailsettings_label]['address']}>)
    if(!AppConfig.configtable['emailsettings'][emailsettings_label]['bcc'].blank?)
      @bcc            = AppConfig.configtable['emailsettings'][emailsettings_label]['bcc']
    end
    
    @headers        = {}    
  end

  def confirm_email(token)
    # base parameters for the email
    self.base_email
    @recipients     = token.user.email
    @subject        = @subjectlabel+'Please confirm your email address'
    urls = Hash.new
    urls['directurl'] = url_for(:controller => 'people/account', :action => :confirmemail, :token => token.token)
    urls['manualurl'] = url_for(:controller => 'people/account', :action => :confirmemail)        
    urls['newtoken'] = url_for(:controller => 'people/account', :action => :confirmemail, :token => 'send')        
    urls['contactus'] = url_for(:controller => 'people/help', :action => :contactform)
    @body           = {:isdemo => @isdemo, :token => token, :urls => urls }  
  end

  def confirm_signup(token,additionaloptions={})
    # base parameters for the email
    self.base_email
    @recipients     = token.user.email
    @subject        = @subjectlabel+'Please confirm your email address'
    urls = Hash.new
    urls['directurl'] = url_for(:controller => 'people/signup', :action => :confirm, :token => token.token)
    urls['manualurl'] = url_for(:controller => 'people/signup', :action => :confirm)        
    urls['newtoken'] = url_for(:controller => 'people/signup', :action => :confirmemail, :token => 'send')        
    urls['contactus'] = url_for(:controller => 'people/help', :action => :contactform)    
    @body           = {:isdemo => @isdemo, :token => token, :urls => urls,:additionaloptions => additionaloptions}  
  end
  
  def welcome(user,is_after_review = false)
    self.base_email
    @recipients     = user.email
    @subject        = @subjectlabel+'Welcome!'
    urls = Hash.new
    urls['profile'] = url_for(:controller => 'people/profile', :action => 'me')
    urls['contactus'] = url_for(:controller => 'people/help', :action => 'contactform')
    @body           = {:isdemo => @isdemo, :user => user, :is_after_review => is_after_review, :urls => urls }  
  end
  
  
  def review_request(reviewuser)
    self.base_email
    # override from
    @from           = "\"#{reviewuser.first_name} #{reviewuser.last_name}\" <#{reviewuser.email}>"
    @recipients     = AppConfig.configtable['mail_system_to']
    @subject        = @subjectlabel+'Account Review Request'
    urls = Hash.new
    urls['reviewurl'] = url_for(:controller => 'colleagues', :action => 'showuser', :id => reviewuser.login)
    @body           = {:isdemo => @isdemo, :reviewuser => reviewuser, :urls => urls }  
    
  end

  def confirm_email_change(token)
    # base parameters for the email
    self.base_email
    @recipients     = token.user.email
    @subject        = @subjectlabel+'Please confirm your email address'
    urls = Hash.new
    urls['directurl'] = url_for(:controller => 'people/account', :action => :confirmemail, :token => token.token)
    urls['manualurl'] = url_for(:controller => 'people/account', :action => :confirmemail)        
    urls['newtoken'] = url_for(:controller => 'people/account', :action => :confirmemail, :token => 'send')        
    urls['contactus'] = url_for(:controller => 'people/help', :action => :contactform)
    @body           = {:isdemo => @isdemo, :token => token, :urls => urls }
  end

  def confirm_password(token)
    # base parameters for the email
    self.base_email
    @recipients     = token.user.email
    @subject        = @subjectlabel+'Please confirm your new password request'
    urls = Hash.new        
    urls['directurl'] = url_for(:controller => 'people/account', :action => 'set_password', :token => token.token)
    urls['manualurl'] = url_for(:controller => 'people/account', :action => 'set_password') 
    urls['contactus'] = url_for(:controller => 'people/help', :action => 'contactform')
    urls['newtoken'] = url_for(:controller => 'people/account', :action => :new_password)        
    @body           = {:isdemo => @isdemo, :urls => urls, :token => token}
  end

  def confirm_revocation(token, revokeuser, urls, sent_at = Time.now)
    self.base_email
    @subject        = subjectlabel+'Please confirm your revocation request'
    @body           = {:isdemo => isdemo, :revokeuser => revokeuser, :urls => urls, :token => token, }
    @recipients     = token.user.email
  end

  def revocation_agreement(adminuser,revokeuser,urls)
    self.base_email
    @subject        = subjectlabel+'Your Contributor Agreement has been revoked'
    @body           = {:isdemo => isdemo, :revokeuser => revokeuser, :urls => urls, :adminuser => adminuser, :agreetime => sent_at}
    @recipients     = adminuser.email,revokeuser.email
  end



end
