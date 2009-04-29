# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'

class AppConfig
  
  @@configtable = Hash.new
  cattr_accessor :configtable
  
  def AppConfig.default_config
    @@configtable.clear
    @@configtable['app_location'] = "localdev"
    @@configtable['appkey'] = Digest::SHA1.hexdigest("no app key present")
    @@configtable['sessionsecret'] = Digest::SHA1.hexdigest("no session key present")
    @@configtable['sudoers'] = Hash.new
    @@configtable['mail_label'] = "localdev"
    
    @@configtable['mail_errors_to'] = "eXtensionAppErrors@extension.org"
    # TODO: may need multiple bcc addresses per functional area
    @@configtable['mail_system_bcc'] = ''
    # TODO: may need multiple noreply addresses per functional area
    @@configtable['mail_system_noreply'] = "pubsite-noreply@extension.org"
    @@configtable['mail_system_noreply_name'] = "eXtension Public Site Notification - Do Not Reply"
  
    #TODO : review these additional settings
    #@@configtable['mail_system_from'] = "eXtensionHelp@extension.org"
    #@@configtable['mail_system_to'] = "eXtensionHelp@extension.org"
    #@@configtable['mail_to_feedback'] = "feedback@extension.org"
    #@@configtable['mail_to_help'] = "eXtensionHelp@extension.org"
    
  
    #Default sites
    @@configtable['faq_site'] = 'http://faq.extension.org'
    @@configtable['events_site'] = 'http://events.extension.org'
    @@configtable['people_site'] = 'https://people.extension.org'
    @@configtable['cop_site'] = 'http://cop.extension.org/wiki'
    @@configtable['collaborate_site'] = 'http://collaborate.extension.org/wiki/'
    @@configtable['about_site'] = 'http://about.extension.org/wiki'
    @@configtable['about_blog'] = 'http://about.extension.org/'
    @@configtable['help_wiki'] = 'http://docs.extension.org/wiki/' 

    # token timeouts are in days
    @@configtable['token_timeout_email'] = 7
    @@configtable['token_timeout_resetpass'] = 1
    @@configtable['token_timeout_revokeagreement'] = 1
    
    # invitation timeout is in days
    @@configtable['invitation_token_timeout'] = 30
    
    # recent deltas are in days
    @@configtable['recent_account_delta'] = 7
    @@configtable['recent_activity_delta'] = 7
    @@configtable['recent_login_delta'] = 7
        
    # tag related
    @@configtable['systemuser_sharedtag_weight'] = 2

    # TODO: review these!!!
    # used to push URL down into the models, for the email crons
    #@@configtable['default_host'] = 'people.extension.org'
    #@@configtable['default_port'] = 443
    #@@configtable['default_protocol'] = 'https'
    #@@configtable['urlwriter_host'] = 'people.extension.org'
    #@@configtable['urlwriter_port'] = 443
    #@@configtable['urlwriter_protocol'] = 'https'

    # used to push IP Address down into the models, for the email crons
    @@configtable['default_request_ip'] = '127.0.0.1'
    @@configtable['request_ip_address'] = '127.0.0.1'
    
    # hardcoded names for the announcement mailing lists
    @@configtable['list-announce'] = 'announce'
    @@configtable['list-announce-all'] = 'announce-all'
    @@configtable['default-list-owner'] = 'extensionlistsmanager@extension.org'
    
    # cache expiry
    @@configtable['cache-expiry'] = {}
    @@configtable['cache-expiry']['Activity'] = 1.hour
    @@configtable['cache-expiry']['User'] = 1.hour
    @@configtable['cache-expiry']['Location'] = 1.hour
    @@configtable['cache-expiry']['Position'] = 1.hour
    @@configtable['cache-expiry']['Institution'] = 1.hour
    @@configtable['cache-expiry']['Community'] = 1.hour
    
    
    # defaults for date ranges for reports
    @@configtable['default_datefield'] = 'created_at'
    @@configtable['default_dateinterval'] = 'withinlastmonth'
    @@configtable['default_timezone'] = 'utc'
          
  end
  
  def AppConfig.load_config
    self.default_config
    configfile ="#{RAILS_ROOT}/config/appconfig.yml"
    if File.exists?(configfile) then
      temp = YAML.load_file(configfile)
      if temp.class == Hash
        @@configtable.merge!(temp)
      end
    end    
  end

  # load the configuration on Class load
  self.load_config  
end