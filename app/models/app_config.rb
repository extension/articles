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
    @@configtable['mail_system_bcc'] = ''
    @@configtable['mail_system_noreply'] = "pubsite-noreply@extension.org"
    @@configtable['mail_system_noreply_name'] = "eXtension Public Site Notification - Do Not Reply"
  
    #Default sites
    @@configtable['faq_site'] = 'http://faq.extension.org'
    @@configtable['events_site'] = 'http://events.extension.org'
    @@configtable['people_site'] = 'https://people.extension.org'
    @@configtable['cop_site'] = 'http://cop.extension.org/wiki'
    @@configtable['collaborate_site'] = 'http://collaborate.extension.org/wiki/'
    @@configtable['about_site'] = 'http://about.extension.org/wiki'
    @@configtable['about_blog'] = 'http://about.extension.org/'
    @@configtable['help_wiki'] = 'http://docs.extension.org/wiki/' 
          
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