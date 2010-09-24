#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--refreshall","-r", GetoptLong::NO_ARGUMENT ]
)

@environment = 'production'
@refreshall = false
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--refreshall'
      @refreshall = true
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


# process all accounts?
if(@refreshall)
  @userlist = User.all(:include => :google_account, :order => 'updated_at DESC')
  @userlist.each do |u|
    if(!u.google_account.blank?)
      puts "Updating Google apps account for #{u.login}..."
      u.google_account.update_apps_account
    end
  end
  
  # groups
  groups_list = GoogleGroup.all
  groups_list.each do |google_group|
    puts "Updating Google groups information for #{google_group.group_id}..."
    google_group.update_apps_group_members # will create/update group as well
  end
else
  needs_update_list = GoogleAccount.needs_apps_update.all(:order => 'updated_at DESC')
  needs_update_list.each do |google_account|
    puts "Updating Google apps account for #{google_account.username}..."
    google_account.update_apps_account
  end
  
  # groups
  groups_list = GoogleGroup.needs_apps_update
  groups_list.each do |google_group|
    puts "Updating Google groups information for #{google_group.group_id}..."
    google_group.update_apps_group_members  # will create/update group as well
  end
end

