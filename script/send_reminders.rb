#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'

progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
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

# clean up expired email and password tokens
# go ahead and cleanup all expired tokens, both emails and password tokens
UserToken.confirmemail.expiredtokens.delete_all
UserToken.resetpassword.expiredtokens.delete_all

###################
# email reminders

# get a list of the users with active confirmemail tokens
waitingusers = UserToken.confirmemail.activetokens.map(&:user)

# get a list of users with unconfirmed emails
unconfirmed = User.active.unconfirmedemail

# process the difference
processusers = unconfirmed - waitingusers

processusers.each do | user |
  user.send_email_reconfirmation
end

###################
# signup reminders

waitingsignups = UserToken.signups.activetokens.map(&:user)
pendingsignups = User.active.pendingsignups

# process the difference
processusers = pendingsignups - waitingsignups

processusers.each do | user |
  user.send_signup_reconfirmation
end

# that's all folks!