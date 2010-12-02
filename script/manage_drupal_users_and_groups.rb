#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--drupaldatabase","-d", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@drupaldatabase = 'prod_create'
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--drupaldatabase'
      @drupaldatabase = arg
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

def update_from_darmok_users(connection,drupaldatabase,mydatabase)
  passwordstring = AppConfig.configtable['passwordstring']
  
  puts "### Starting replacement of drupal user data from darmok data..."
  
  puts "starting user table replacement..."
  
  sql = "REPLACE INTO #{drupaldatabase}.users (uid,name,pass,mail,created,status)"
  sql +=  " SELECT #{mydatabase}.accounts.id, #{mydatabase}.accounts.login,'#{passwordstring}', #{mydatabase}.accounts.email,UNIX_TIMESTAMP(#{mydatabase}.accounts.created_at),(NOT(#{mydatabase}.accounts.retired) AND (#{mydatabase}.accounts.vouched))"
  sql +=  " FROM #{mydatabase}.accounts"
  sql +=  " WHERE #{mydatabase}.accounts.type = 'User'"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal users table: #{err}"
    return false
  end

  puts "finished user table replacement."
  
  
  puts "starting authmap table replacement..."
  
  sql = "REPLACE INTO #{drupaldatabase}.authmap (aid,uid,authname,module) SELECT uid,uid,CONCAT('https://people.extension.org/',name), 'openid' FROM #{drupaldatabase}.users;"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the authmap table: #{err}"
    return false
  end

  puts "finished authmap replacement."
  
  
  return true
end

def new_groups_from_darmok_communities(connection,drupaldatabase,mydatabase)
  
  puts "### Starting new group creation from darmok communities..."
  
  puts "inserting revisions..."
  
  # insert into revisions
  sql = "INSERT INTO #{drupaldatabase}.node_revision (nid,uid,title,log,timestamp) SELECT 0,1,#{mydatabase}.communities.name,'Added by synchronization script',UNIX_TIMESTAMP() FROM #{mydatabase}.communities WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NULL;"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during revision insert: #{err}"
    return false
  end
  
  puts "revisions inserted..."
  
  ####### # insert into nodes
  
  
  puts "inserting nodes..."
  
  sql = "INSERT INTO #{drupaldatabase}.node (vid,type,language,title,uid,created,changed,promote) SELECT vid,'group','und',#{drupaldatabase}.node_revision.title,1,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1 FROM #{drupaldatabase}.node_revision WHERE #{drupaldatabase}.node_revision.nid = 0 and #{drupaldatabase}.node_revision.log = 'Added by synchronization script';"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during node insert: #{err}"
    return false
  end
  
  puts "nodes inserted..."
  

  ####### #  set the revision node id based on name
  
  puts "setting the node revision id..."
  
  sql = "UPDATE #{drupaldatabase}.node_revision,#{drupaldatabase}.node SET #{drupaldatabase}.node_revision.nid = #{drupaldatabase}.node.nid WHERE #{drupaldatabase}.node.vid = #{drupaldatabase}.node_revision.vid AND #{drupaldatabase}.node.type = 'group' AND #{drupaldatabase}.node_revision.title = #{drupaldatabase}.node.title;"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during node revision id set: #{err}"
    return false
  end
  
  puts "node revision id set..."
  
  
  

  ####### #  set the darmok community association based on name
  
  puts "updating the darmok communities with drupal node ids..."
  
  sql = "UPDATE #{mydatabase}.communities,#{drupaldatabase}.node SET #{mydatabase}.communities.drupal_node_id = #{drupaldatabase}.node.nid WHERE #{drupaldatabase}.node.type = 'group' AND  #{mydatabase}.communities.name =
  CAST(#{drupaldatabase}.node.title AS CHAR CHARACTER SET utf8) COLLATE utf8_unicode_ci AND #{mydatabase}.communities.drupal_node_id IS NULL;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during darmok community update: #{err}"
    return false
  end
  
  puts "darmok communities updated..."

  return true;
  
end


def update_groups_from_darmok_communities(connection,drupaldatabase,mydatabase)
  
  puts "### Starting group update from darmok communities..."
  
  ####### #  update the nodes table
  
  puts "updating node table..."
  
  sql = "UPDATE #{drupaldatabase}.node,#{mydatabase}.communities SET #{drupaldatabase}.node.title = #{mydatabase}.communities.name,#{drupaldatabase}.node.uid = 1 WHERE #{drupaldatabase}.node.nid =  #{mydatabase}.communities.drupal_node_id AND #{drupaldatabase}.node.type = 'group' AND #{mydatabase}.communities.connect_to_drupal = 1;"
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during node table update: #{err}"
    return false
  end
  
  puts "node table updated..."


  ####### # update revisions table
  
  puts "updating revisions table..."
  
  sql = "UPDATE #{drupaldatabase}.node_revision,#{drupaldatabase}.node SET #{drupaldatabase}.node_revision.title = #{drupaldatabase}.node.title,#{drupaldatabase}.node_revision.log = 'Updated by synchronization script',#{drupaldatabase}.node_revision.uid = 1 WHERE #{drupaldatabase}.node.vid = #{drupaldatabase}.node_revision.vid AND #{drupaldatabase}.node.type = 'group'  AND #{drupaldatabase}.node_revision.title != #{drupaldatabase}.node.title;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during revisions table update: #{err}"
    return false
  end
  
  puts "revisions table updated..."


  ####### # update the og table
  
  puts "updating the og table..."
  
  sql = "REPLACE INTO #{drupaldatabase}.og (gid,etid,entity_type,label,state,created) SELECT #{mydatabase}.communities.drupal_node_id,#{mydatabase}.communities.drupal_node_id,'node',#{mydatabase}.communities.name,1,UNIX_TIMESTAMP() FROM #{mydatabase}.communities WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  puts "og table updated..."


  ####### # delete current memberships
  
  puts "deleting managed memberships from the og_users_roles table..."
  
  sql = "DELETE #{drupaldatabase}.og_users_roles.* FROM #{drupaldatabase}.og_users_roles,#{drupaldatabase}.og,#{mydatabase}.communities WHERE #{drupaldatabase}.og_users_roles.gid = #{drupaldatabase}.og.gid AND #{drupaldatabase}.og.etid = #{mydatabase}.communities.drupal_node_id AND #{mydatabase}.communities.connect_to_drupal = 1;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og_users_roles deletion: #{err}"
    return false
  end
  
  puts "og_users_roles managed memberships deleted..."


  ####### # set current memberships
  
  puts "creating managed memberships in the og_users_roles table..."
  
  # hardcoded roles - do not change these roles in drupal!!
  # leader = 3
  # member = 2

  sql = "INSERT INTO #{drupaldatabase}.og_users_roles (uid,rid,gid) SELECT #{mydatabase}.communityconnections.user_id,IF(#{mydatabase}.communityconnections.connectiontype = 'leader',3,2),#{drupaldatabase}.og.gid FROM  #{drupaldatabase}.og, #{mydatabase}.communities, #{mydatabase}.communityconnections WHERE #{drupaldatabase}.og.etid = #{mydatabase}.communities.drupal_node_id AND #{mydatabase}.communities.id = #{mydatabase}.communityconnections.community_id AND #{mydatabase}.communityconnections.connectiontype IN ('leader','member') AND #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og_users_roles creation: #{err}"
    return false
  end
  
  puts "og_users_roles managed memberships created..."

end




#################################
# Main

# my database connection 
mydatabase = User.connection.instance_variable_get("@config")[:database]
# replace/insert user accounts
result = update_from_darmok_users(User.connection,@drupaldatabase,mydatabase)
# new groups
result = new_groups_from_darmok_communities(User.connection,@drupaldatabase,mydatabase)
# groups update
result = update_groups_from_darmok_communities(User.connection,@drupaldatabase,mydatabase)
