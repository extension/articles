# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ApiKeyEvent < ActiveRecord::Base
  belongs_to :api_key
  serialize :additionaldata

  def self.log_event(requestaction,api_key,additionaldata = nil)
    logger.debug("#{additionaldata.inspect}")
    options = {:requestaction => requestaction, :api_key => api_key, :ipaddr => AppConfig.configtable['request_ip_address'], :additionaldata => additionaldata}
    return self.create(options)
  end
  
end
