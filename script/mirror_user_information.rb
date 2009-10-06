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
  
  identitysql = "SELECT users.id as userid, users.login as login,users.email as email,"
  identitysql += "users.first_name as first_name,users.last_name as last_name,"
  identitysql += "users.title as title,users.retired as retired,"
  identitysql += "users.created_at as created_at, users.updated_at as updated_at,"
  identitysql += "locations.abbreviation as state,counties.name as county,institutions.name as university"
  identitysql += " FROM users"
  identitysql += " LEFT JOIN locations ON users.location_id = locations.id"
  identitysql += " LEFT JOIN counties ON users.county_id = counties.id"
  identitysql += " LEFT JOIN communities ON (users.institution_id = communities.id AND communities.type = 'Institution')"
  identitysql += " WHERE (users.vouched = 1 OR users.retired = 1)"
  identitysql += " AND users.emailconfirmed = 1"
  # keep peoplebot out of the data
  identitysql += " AND users.id != 1"
  
  
  sql = "REPLACE INTO #{userinfodb}.users (id,login,email,first_name,last_name,title,retired,created_at,updated_at,state,county,university)"
  sql +=  " SELECT identitysourcedata.userid, identitysourcedata.login,identitysourcedata.email,identitysourcedata.first_name,identitysourcedata.last_name,"
  sql +=  "identitysourcedata.title,identitysourcedata.retired,identitysourcedata.created_at,identitysourcedata.updated_at,"
  sql +=  "identitysourcedata.state,identitysourcedata.county,identitysourcedata.university"
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

