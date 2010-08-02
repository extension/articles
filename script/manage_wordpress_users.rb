#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--wordpressdatabase","-w", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@wordpressdatabase = 'demo_aboutblog'
@editor_privs = "a:1:{s:6:\"editor\";s:1:\"1\";}"
@admin_privs = "a:1:{s:13:\"administrator\";b:1;}"
@expired_privs = "a:0:{}"

progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--wordpressdatabase'
      @wordpressdatabase = arg
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

def update_from_darmok_users(connection,wordpressdatabase,mydatabase)
  passwordstring = AppConfig.configtable['passwordstring']
  
  puts "### Starting replacement of wordpress user data from darmok data..."
  
  puts "starting user table replacement..."
  
  sql = "REPLACE INTO #{wordpressdatabase}.wp_users (id,user_login,user_pass,user_email,user_nicename,display_name)"
  sql +=  " SELECT #{mydatabase}.users.id,#{mydatabase}.users.login,'#{passwordstring}',#{mydatabase}.users.email,#{mydatabase}.users.login,(CONCAT(#{mydatabase}.users.first_name,' ',#{mydatabase}.users.last_name))"
  sql +=  " FROM #{mydatabase}.users WHERE (NOT(#{mydatabase}.users.retired) AND (#{mydatabase}.users.vouched))"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the wordpress users table: #{err}"
    return false
  end

  puts "finished user table replacement."
  
  puts "starting wp_openid_identities table replacement..."
  
  sql = "REPLACE INTO #{wordpressdatabase}.wp_openid_identities (uurl_id,user_id,url) SELECT id,id,CONCAT('https://people.extension.org/',user_login) FROM #{wordpressdatabase}.wp_users;"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the wp_openid_identities table: #{err}"
    return false
  end

  puts "finished wp_openid_identities replacement."
  
  
  return true
end

def set_editor_privs(connection,wordpressdatabase,mydatabase)
  ####### # update the user_meta table - editor privs
  
  puts "updating the user_meta table - giving all users editor privs..."
  
  sql = "REPLACE INTO #{wordpressdatabase}.wp_usermeta (umeta_id,user_id,meta_key,meta_value) SELECT #{wordpressdatabase}.wp_users.id, #{wordpressdatabase}.wp_users.id, 'wp_capabilities', '#{@editor_privs}' FROM #{wordpressdatabase}.wp_users;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  puts "user_meta table updated - editors set..."
  return true
  
end
  
def set_admin_privs(connection,wordpressdatabase,mydatabase)
  ####### # update the user_meta table - admin privs
  
  puts "updating the user_meta table - setting admin privs..."
  
sql = "REPLACE INTO #{wordpressdatabase}.wp_usermeta (umeta_id,user_id,meta_key,meta_value) SELECT #{mydatabase}.users.id, #{mydatabase}.users.id, 'wp_capabilities', '#{@admin_privs}' FROM #{mydatabase}.users WHERE #{mydatabase}.users.is_admin = 1;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  puts "user_meta table updated - admins set..."
  return true
  
end

def set_expired_privs(connection,wordpressdatabase,mydatabase)
  ####### # update the user_meta table - disable users that are retired in people
  
  puts "updating the user_meta table - expiring retired accounts..."
  
  sql = "REPLACE INTO #{wordpressdatabase}.wp_usermeta (umeta_id,user_id,meta_key,meta_value) SELECT #{mydatabase}.users.id, #{mydatabase}.users.id, 'wp_capabilities', '#{@expired_privs}' FROM #{mydatabase}.users WHERE #{mydatabase}.users.retired = 1;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  puts "user_meta table updated - editors set..."
  return true
  
end
#################################
# Main

# my database connection 
mydatabase = User.connection.instance_variable_get("@config")[:database]
# replace/insert user accounts
result = update_from_darmok_users(User.connection,@wordpressdatabase,mydatabase)
result = set_editor_privs(User.connection,@wordpressdatabase,mydatabase)
result = set_admin_privs(User.connection,@wordpressdatabase,mydatabase)
result = set_expired_privs(User.connection,@wordpressdatabase,mydatabase)

