#!/usr/bin/env ruby

ENV["RAILS_ENV"] = "production"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

qw_role = Role.find_by_name('Uncategorized Question Wrangler')
qw_user_roles = UserRole.find(:all, :conditions => { :role_id => qw_role.id })

qw_user_roles.each do |qw|
  qw.delete
end

qw_role.delete