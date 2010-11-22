#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--wordpressdatabase","-w", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--multiuser", "-m", GetoptLong::NO_ARGUMENT]
)

@environment = 'production'
@wordpressdatabase = 'demo_aboutblog'
@editor_privs = "a:1:{s:6:\"editor\";s:1:\"1\";}"
@admin_privs = "a:1:{s:13:\"administrator\";b:1;}"
@expired_privs = "a:0:{}"
@multiuser = false

progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--wordpressdatabase'
      @wordpressdatabase = arg
    when '--multiuser'
      @multiuser = true
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

def get_multiuser_blog_ids(connection,wordpressdatabase)
  puts "### Getting blog ids for wordpress multiuser replacement of wordpress user data from darmok data..."
  
  sql = "SELECT DISTINCT `blog_id` FROM  `#{wordpressdatabase}`.`wp_blogs`"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
    return result
  rescue => err
    $stderr.puts "ERROR: Exception raised during multiuser blog id query of the wordpress blog: #{err}"
    return false
  end

  puts "finished blog id query."
  
  
end

def update_from_darmok_users(connection,wordpressdatabase,mydatabase)
  passwordstring = AppConfig.configtable['passwordstring']
  
  puts "### Starting replacement of wordpress user data from darmok data..."
  
  puts "starting user table replacement..."
  
  sql = "REPLACE INTO #{wordpressdatabase}.wp_users (id,user_login,user_pass,user_email,user_nicename,display_name)"
  sql +=  " SELECT #{mydatabase}.accounts.id,#{mydatabase}.accounts.login,'#{passwordstring}',#{mydatabase}.accounts.email,#{mydatabase}.accounts.login,(CONCAT(#{mydatabase}.accounts.first_name,' ',#{mydatabase}.accounts.last_name))"
  sql +=  " FROM #{mydatabase}.accounts WHERE (#{mydatabase}.accounts.vouched AND #{mydatabase}.accounts.type = 'User')"
  
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

def set_editor_privs(connection,wordpressdatabase,mydatabase, wp_capabilities = "wp_capabilities", blog_id_separator = 0)
  ####### # update the user_meta table - editor privs
  
  puts "updating the user_meta table - giving all users editor privs..."
  sql = "REPLACE INTO #{wordpressdatabase}.wp_usermeta (umeta_id,user_id,meta_key,meta_value) SELECT #{wordpressdatabase}.wp_users.id + #{blog_id_separator} AS 'umeta_id', #{wordpressdatabase}.wp_users.id, '#{wp_capabilities}', '#{@editor_privs}' FROM #{wordpressdatabase}.wp_users;"  
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the editor user_meta table update: #{err}"
    return false
  end
  
  puts "user_meta table updated - editors set..."
  return true

end
  
def set_admin_privs(connection,wordpressdatabase,mydatabase, wp_capabilities = "wp_capabilities", blog_id_separator = 0)
  ####### # update the user_meta table - admin privs
  
  puts "updating the user_meta table - setting admin privs..."
  
  sql = "REPLACE INTO #{wordpressdatabase}.wp_usermeta (umeta_id,user_id,meta_key,meta_value) SELECT #{mydatabase}.accounts.id + #{blog_id_separator} AS 'umeta_id', #{mydatabase}.accounts.id, '#{wp_capabilities}', '#{@admin_privs}' FROM #{mydatabase}.accounts WHERE #{mydatabase}.accounts.is_admin = 1;"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the admin user_meta table update: #{err}"
    return false
  end
  
  puts "user_meta table updated - admins set..."
  return true
  
end

def set_expired_privs(connection,wordpressdatabase,mydatabase, wp_capabilities = "wp_capabilities", blog_id_separator = 0)
  ####### # update the user_meta table - disable users that are retired in people
  
  puts "updating the user_meta table - expiring retired accounts..."
  
  sql = "REPLACE INTO #{wordpressdatabase}.wp_usermeta (umeta_id,user_id,meta_key,meta_value) SELECT (#{blog_id_separator} + #{mydatabase}.accounts.id), #{mydatabase}.accounts.id, '#{wp_capabilities}', '#{@expired_privs}' FROM #{mydatabase}.accounts WHERE #{mydatabase}.accounts.retired = 1 AND #{mydatabase}.accounts.type = 'User';"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the expired user_meta table update: #{err}"
    return false
  end
  
  puts "user_meta table updated - retired accounts expired..."
  return true
  
end
#################################
# Main

# my database connection 
mydatabase = User.connection.instance_variable_get("@config")[:database]

# get blog ids if running with multiuser arg
blog_ids = get_multiuser_blog_ids(User.connection,@wordpressdatabase) if @multiuser
result = update_from_darmok_users(User.connection,@wordpressdatabase,mydatabase)


if @multiuser
  blog_ids.each do |blog_id|
    blog_id_separator = blog_id[0].to_i * 1000000 # create an id space for each blogs permissions so there isn't any overlap
    result = set_editor_privs(User.connection,@wordpressdatabase,mydatabase, "wp_#{blog_id}_capabilities", blog_id_separator)
    result = set_admin_privs(User.connection,@wordpressdatabase,mydatabase, "wp_#{blog_id}_capabilities", blog_id_separator)
    result = set_expired_privs(User.connection,@wordpressdatabase,mydatabase, "wp_#{blog_id}_capabilities", blog_id_separator)
  end
else
  # replace/insert user accounts
  result = set_editor_privs(User.connection,@wordpressdatabase,mydatabase)
  result = set_admin_privs(User.connection,@wordpressdatabase,mydatabase)
  result = set_expired_privs(User.connection,@wordpressdatabase,mydatabase)
end
