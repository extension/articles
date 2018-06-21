# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PageRedirectLog < ActiveRecord::Base
  serialize :data

  belongs_to :person

  SET_INITIAL_REDIRECT = 1
  CHANGE_REDIRECT_URL = 2
  REDIRECTION_REMOVED = 3 # should be an eye rolly emoji, but articles is not utf8mb4

  DESCRIPTIONS =  {SET_INITIAL_REDIRECT => 'Redirected page',
                   CHANGE_REDIRECT_URL => 'Changed redirect url',
                   REDIRECTION_REMOVED => 'Removed redirection'}


  def description
    DESCRIPTIONS.include?(self.event) ? DESCRIPTIONS[self.event] : "Unknown"
  end

  def self.log_redirect(person, event, data = nil)
    newpl = self.new do |pl|
      pl.person = person
      pl.event = event
      pl.ip = Settings.request_ip_address
      pl.data = data
    end
    newpl.save
  end
end
