# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ApiKey < ActiveRecord::Base
  belongs_to :user
  has_many :api_key_events
  
  before_create :generate_keyvalue
  
  def generate_keyvalue
    randval = rand
    self.keyvalue = Digest::SHA1.hexdigest(AppConfig.configtable['sessionsecret']+self.user_id.to_s+self.name+randval.to_s)
  end
  
end