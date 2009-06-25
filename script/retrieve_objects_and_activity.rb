#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--refreshall","-r", GetoptLong::NO_ARGUMENT ],
  [ "--identitydatabase","-i", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--application","-a", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@refreshall = false
@doapplication = 'all'
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--identitydatabase'
      @identitydatabase = arg
    when '--refreshall'
      @refreshall = true
    when '--application'
      @doapplication = arg
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


###### go! ###########
ActivityApplication.active.activitysources.each do |application|
  if(@doapplication == 'all' or @doapplication.downcase == application.shortname)
    result = application.get_activityobjects(@refreshall)
    if(result)
      application.get_activity(@refreshall)
    end
  end
end