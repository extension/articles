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

# let's go!
puts "Refreshing NumberSummary cache (for index summary)..."
@total = NumberSummary.new({:forcecacheupdate => true})
@total.totalpeople
@total.newpeople
@total.active
@total.applications
@total.communities
@total.locations
@total.positions
@total.agreements

# output the rails cache stats
pp Rails.cache.stats