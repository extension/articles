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


# find sessions starting tomorrow within the hour that this script is running
tomorrow_learn_sessions = LearnSession.find_tomorrow_sessions
if(!tomorrow_learn_sessions.blank?)
  tomorrow_learn_sessions.each do |learn_session|
    interested_users = learn_session.connected_users(LearnConnection::INTERESTED)
    if(!interested_users.blank?)
      interested_users.each do |person|
        Notification.create(:notifytype => Notification::LEARN_UPCOMING_SESSION, :account => person, :creator => User.systemuser, :additionaldata => {:learn_session_id => learn_session.id})
      end
      puts "Created #{interested_users.size} notification(s) for tomorrow's Learn Session (ID: #{learn_session.id})"
    else
      puts "No notifications for tomorrow's Learn Session (ID: #{learn_session.id})"
    end
  end
end

    