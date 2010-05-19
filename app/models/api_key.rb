# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ApiKey < ActiveRecord::Base
  belongs_to :user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  has_many :api_key_events
  
  before_create :generate_keyvalue
  
  def generate_keyvalue
    randval = rand
    self.keyvalue = Digest::SHA1.hexdigest(AppConfig.configtable['sessionsecret']+self.user_id.to_s+self.name+randval.to_s)
  end
  
  def total_usage
    self.api_key_events.count
  end
  
  def today_usage
    self.api_key_events.count(:all, :conditions => "DATE(created_at) = DATE(NOW())")
  end
  
  def self.systemkey
    find(1)
  end
end