#!/usr/bin/env ruby
# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
# === PURPOSE:
# send AaE away reminders to those who have opted out of receiving AaE questions 
#

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

# find all the AaE vacators that have either been out of it for at least two weeks and have have no reminders sent or those that have been
# out of it for at least four weeks have had no four week reminder sent
# only a two and four week reminder will be sent
two_week_vacators = User.find(:all, :conditions => ["vacated_aae_at <= ? AND first_aae_away_reminder = false AND second_aae_away_reminder = false", 2.weeks.ago]) 
four_week_vacators = User.find(:all, :conditions => ["vacated_aae_at <= ? AND second_aae_away_reminder = false", 4.weeks.ago]) 
 
# loop through all the experts who have opted out of receiving questions according to said criteria above
two_week_vacators.each do |vacator|
  begin
    NotificationMailer.deliver_aae_away_reminder(vacator)
  rescue Exception => e
    $stderr.puts "Unable to deliver aae reminder email for expert #{vacator.email}, #{e.message}"
    next
  end
  
  vacator.update_attribute(:first_aae_away_reminder, true)
end

four_week_vacators.each do |vacator|
  begin
    NotificationMailer.deliver_aae_away_reminder(vacator)
  rescue Exception => e
    $stderr.puts "Unable to deliver aae reminder email for expert #{vacator.email}, #{e.message}"
    next
  end
  
  vacator.update_attribute(:second_aae_away_reminder, true)
end

