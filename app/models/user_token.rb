# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'

class UserToken < ActiveRecord::Base
  belongs_to :user
  EMAIL = 1
  RESETPASS = 2
  ADMIN_REVOKEAGREENT = 3
  
  SIGNUP = 4
  
  serialize :tokendata
  before_create :generate_token, :set_expires
  
  named_scope :confirmemail,  :conditions => "tokentype = #{EMAIL}"
  named_scope :resetpassword, :conditions => "tokentype = #{RESETPASS}"
  named_scope :signups, :conditions => "tokentype = #{SIGNUP}"
  
  named_scope :expiredtokens, :conditions => "expires_at < '#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}'"
  named_scope :activetokens, :conditions => "expires_at >= '#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}'"


  def token_expired?
    self.token and self.expires_at and (Time.now.utc > self.expires_at)
  end
  
  def extendtoken
    self.generate_token
    self.set_expires
    self.extended_count += 1
    self.extended_at = Time.now.utc
    self.save
  end
  
  protected
  
  def generate_token
    randval = rand
    self.token = Digest::SHA1.hexdigest(AppConfig.configtable['sessionsecret']+self.user.email+self.user.password+randval.to_s)  
  end  
  
  def set_expires
    case self.tokentype
    when EMAIL
      daysvalid = AppConfig.configtable['token_timeout_email']
    when SIGNUP
      daysvalid = AppConfig.configtable['token_timeout_email']
    when RESETPASS
      daysvalid = AppConfig.configtable['token_timeout_resetpass']
    when ADMIN_REVOKEAGREENT
      daysvalid = AppConfig.configtable['token_timeout_revokeagreement']
    else
      return
    end
    self.expires_at = Time.at(Time.now.to_i + (daysvalid * 86400)).utc
  end

  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
  end  
end
