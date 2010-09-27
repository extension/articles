#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--groupsonly","-g", GetoptLong::NO_ARGUMENT ],
  [ "--startdate","-d", GetoptLong::OPTIONAL_ARGUMENT ]
)

@start_date = '2010-09-25'
@environment = 'production'
@groupsonly = false
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--groupsonly'
      @groupsonly = true
    when '--startdate'
      @start_date = arg
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

def update_apps_users
  # updated accounts
  needs_update_list = GoogleAccount.needs_apps_update.no_apps_error.all(:order => 'updated_at DESC')
  needs_update_list.each do |google_account|
    puts "Updating Google apps account for #{google_account.username}..."
    google_account.update_apps_account
  end
  
  # new accounts
  needs_update_list = GoogleAccount.null_apps_update.no_apps_error.all(:conditions => "DATE(created_at) > '#{@start_date}'", :order => 'updated_at DESC')
  needs_update_list.each do |google_account|
    puts "Creating Google apps account for #{google_account.username}..."
    google_account.update_apps_account
  end
end

def update_apps_groups
  groups_list = GoogleGroup.needs_apps_update.no_apps_error
  groups_list.each do |google_group|
    puts "Creating/Updating Google groups information for #{google_group.group_id}..."
    google_group.update_apps_group_members  # will create/update group as well
  end
end
 

# process all accounts?
if(!@groupsonly)
  update_apps_users
end
update_apps_groups

