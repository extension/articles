#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--identitydatabase","-i", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@userinfodb = 'darmokusermirror'
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--identitydatabase'
      @identitydatabase = arg
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



def update_from_identity_users(connection,userinfodb,mydatabase)
  
  ActiveRecord::Base::logger.info "##################### Starting users data retrieval..."
  
  identitysql = "SELECT accounts.id as userid, accounts.login as login,accounts.email as email,"
  identitysql += "accounts.first_name as first_name,accounts.last_name as last_name,"
  identitysql += "accounts.title as title,accounts.retired as retired,"
  identitysql += "accounts.created_at as created_at, accounts.updated_at as updated_at,"
  identitysql += "locations.abbreviation as state,counties.name as county"
  identitysql += " FROM accounts"
  identitysql += " LEFT JOIN locations ON accounts.location_id = locations.id"
  identitysql += " LEFT JOIN counties ON accounts.county_id = counties.id"
  identitysql += " WHERE (accounts.vouched = 1 OR accounts.retired = 1)"
  identitysql += " AND accounts.emailconfirmed = 1"
  identitysql += " AND accounts.type = 'User'"

  # keep peoplebot out of the data
  identitysql += " AND accounts.id != 1"
  
  
  sql = "REPLACE INTO #{userinfodb}.users (id,login,email,first_name,last_name,title,retired,created_at,updated_at,state,county)"
  sql +=  " SELECT identitysourcedata.userid, identitysourcedata.login,identitysourcedata.email,identitysourcedata.first_name,identitysourcedata.last_name,"
  sql +=  "identitysourcedata.title,identitysourcedata.retired,identitysourcedata.created_at,identitysourcedata.updated_at,"
  sql +=  "identitysourcedata.state,identitysourcedata.county"
  sql +=  " FROM (#{identitysql}) as identitysourcedata"
  
  # execute the sql
  connection = User.connection
  begin
    result = connection.execute(sql)
  rescue => err
    ActiveRecord::Base::logger.error "ERROR: Exception raised during users data retrieval: #{err}"
    return false
  end

  ActiveRecord::Base::logger.info "Finished users data retrieval."
  return true
end

#################################
# Main

# my database connection - the account I use needs select on the identity/users db
mydatabase = User.connection.instance_variable_get("@config")[:database]
# go!
result = update_from_identity_users(User.connection,@userinfodb,mydatabase)

