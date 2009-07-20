#!/usr/bin/env ruby
# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
# === PURPOSE:
# create notifications for all submitted questions that are > @@configtable['aae_escalation_delta'] hours at the time the script is run.
#
# TODO:  review the logic of all this.  If it's running as part of cron.hourly - the sit time is likely already 11-20 hours on top of the delta time

require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--hours","-h", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@hours = AppConfig.configtable['aae_escalation_delta']
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--hours'
      @hours = arg.to_i
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

# loop through all the root categories that we might have escalations for
Category.root_categories.each do |category|
   # question count
   if(SubmittedQuestion.escalated(@hours,category).count > 0)
     begin
       NotificationMailer.deliver_aae_escalation_for_category(category,@hours)
     rescue
       # TODO:
     end
   end
end
