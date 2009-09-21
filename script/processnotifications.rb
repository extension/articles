#!/usr/bin/env ruby
#TODO: refactor this script
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--limit","-l", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@limit = 10

progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--limit'
      @limit = arg
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

# main
notifications = Notification.tosend.find(:all, :limit => @limit)
@notificationcount = notifications.size
if (notifications.nil? or notifications.empty?)
  puts "No notifications to processs"
end

@successcount = 0
@failurecount = 0

notifications.each do |notification|
  puts "Sending email for notification:#{notification.id}..."
  notificationresult = notification.send_email
  if(notificationresult)
    puts "Success!"
    @successcount += 1;
  else
    puts "Fail!"
    @failurecount += 1;
  end
  
end

# log
if(@notificationcount > 0)
  AdminEvent.log_data_event(AdminEvent::SENT_NOTIFICATIONS, {:notificationcount => @notificationcount, :successcount => @successcount, :failurecount => @failurecount})
end
