# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class MainMailer < ActionMailer::Base
  
  def join_confirmation(user, url)
    @subject    = "Confirm #{APPLICATION_NAME} registration"
    @body       = { :url => url, :user => user }
    @recipients = "#{user} <#{user.email}>"
    @from       = "#{APPLICATION_NAME} <no-reply@#{APPLICATION_DOMAIN}>"
    @sent_on    = Time.now
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers    = {}
  end

  def reset_password(user, url)
    @subject    = "#{APPLICATION_NAME} password help"
    @body       = { :url => url, :user => user }
    @recipients = "#{user} <#{user.email}>"
    @from       = "#{APPLICATION_NAME} <no-reply@#{APPLICATION_DOMAIN}>"
    @sent_on    = Time.now
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers    = {}
  end
  
  def confirm_email(user, urls, sent_at = Time.now)
    if(AppConfig.configtable['site_label'] == 'production')
      isdemo = false
      subjectlabel = "eXtension Initiative: "
    else
      isdemo = true
      subjectlabel = "eXtension Initiative (#{AppConfig.configtable['site_label']}): "
    end
    @subject        = subjectlabel+'Please confirm your email address'
    @body           = {:isdemo => isdemo, :urls => urls, :user => user}
    @recipients     = user.email
    @from           = %("eXtension (No Reply)" <#{AppConfig.configtable['mail_system_from']}>)
    @sent_on        = sent_at
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers        = {}
  end
  
  def confirm_password(token, urls, sent_at = Time.now)
    if(AppConfig.configtable['site_label'] == 'production')
      isdemo = false
      subjectlabel = "eXtension Initiative: "
    else
      isdemo = true
      subjectlabel = "eXtension Initiative (#{AppConfig.configtable['site_label']}): "
    end
    @subject        = subjectlabel+'Please confirm your password reset request'
    @body           = {:isdemo => isdemo, :urls => urls, :token => token}
    @recipients     = token.user.email
    @from           = %("eXtension (No Reply)" <#{AppConfig.configtable['mail_system_from']}>)
    @sent_on        = sent_at
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers        = {}
  end
  
  def feed_error(feed_url, exception)
    @subject    = "#{APPLICATION_NAME} feed issue"
    @body       = { :exception => exception, :feed_url => feed_url }
    @recipients = "eXtensionAppErrors@extension.org"
    @from       = "eXtension Error Reporter <exdev@extension.org>"
    @sent_on    = Time.now
    @headers    = {}    
  end
  
  def search_error(host, full_message)
    @subject = "[pubsite-#{AppConfig.configtable['site_label']}] Search Error"
    @from = %("eXtension Error Reporter" <exdev@extension.org>)
    @recipients =  "eXtensionAppErrors@extension.org"
    @body["message"] = full_message
    @body["host"] = host
    @headers = {}
  end
  
  def deliver!(mail = @mail)
    begin
      super
    rescue Exception => e
      logger.error(e)
    end
  end
  
end
