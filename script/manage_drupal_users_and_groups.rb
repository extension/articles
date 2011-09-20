#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--drupaldatabase","-d", GetoptLong::OPTIONAL_ARGUMENT ]
)
ADMIN_ROLE = 3

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
  
  sql = "INSERT INTO #{drupaldatabase}.users (uid,name,pass,mail,created,status)"
  sql +=  " SELECT #{mydatabase}.accounts.id, #{mydatabase}.accounts.login,'#{passwordstring}', #{mydatabase}.accounts.email,UNIX_TIMESTAMP(#{mydatabase}.accounts.created_at),(NOT(#{mydatabase}.accounts.retired) AND (#{mydatabase}.accounts.vouched))"
  sql +=  " FROM #{mydatabase}.accounts"
  sql +=  " WHERE #{mydatabase}.accounts.type = 'User'"
  sql +=  " ON DUPLICATE KEY UPDATE name=#{mydatabase}.accounts.login, pass='#{passwordstring}',mail=#{mydatabase}.accounts.email,status=(NOT(#{mydatabase}.accounts.retired) AND (#{mydatabase}.accounts.vouched))"
  
  
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal users table: #{err}"
    return false
  end

  puts "finished user table replacement."
  
  # administrative privs
  puts "### Starting replacement of drupal admin roles data from darmok admin accounts"
  
  # drop admin role roles first
  begin
    result = connection.execute("DELETE from #{drupaldatabase}.users_roles where rid = #{ADMIN_ROLE}")
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal user_roles table: #{err}"
    return false
  end
  
  sql = "INSERT INTO #{drupaldatabase}.users_roles (uid,rid)"
  sql +=  " SELECT #{drupaldatabase}.users.uid, 3"
  sql +=  " FROM #{mydatabase}.accounts,#{drupaldatabase}.users"
  sql +=  " WHERE #{mydatabase}.accounts.is_admin = 1"
  sql +=  " AND #{mydatabase}.accounts.id = #{drupaldatabase}.users.uid"
  # execute the sql
  
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal user_roles table: #{err}"
    return false
  end

  puts "finished roles replacement"
  
  
  # first names
  puts "starting user first name data table replacement..."
  sql = "INSERT INTO #{drupaldatabase}.field_data_field_first_name (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_first_name_value, field_first_name_format)"
  sql +=  " SELECT 'user', 'user', 0, #{mydatabase}.accounts.id, #{mydatabase}.accounts.id, 'und', 0, #{mydatabase}.accounts.first_name, NULL"
  sql +=  " FROM #{mydatabase}.accounts"
  sql +=  " WHERE #{mydatabase}.accounts.type = 'User'"
  sql +=  " ON DUPLICATE KEY UPDATE field_first_name_value=#{mydatabase}.accounts.first_name"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal users first name table: #{err}"
    return false
  end
  puts "finished user first name data table replacement."

  puts "starting user first name revisions table replacement..."
  sql = "INSERT INTO #{drupaldatabase}.field_revision_field_first_name (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_first_name_value, field_first_name_format)"
  sql +=  " SELECT 'user', 'user', 0, #{mydatabase}.accounts.id, #{mydatabase}.accounts.id, 'und', 0, #{mydatabase}.accounts.first_name, NULL"
  sql +=  " FROM #{mydatabase}.accounts"
  sql +=  " WHERE #{mydatabase}.accounts.type = 'User'"
  sql +=  " ON DUPLICATE KEY UPDATE field_first_name_value=#{mydatabase}.accounts.first_name"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal users first name revisions table: #{err}"
    return false
  end
  puts "finished user first name revisions table replacement."

  # last names
  puts "starting user last name data table replacement..."
  sql = "INSERT INTO #{drupaldatabase}.field_data_field_last_name (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_last_name_value, field_last_name_format)"
  sql +=  " SELECT 'user', 'user', 0, #{mydatabase}.accounts.id, #{mydatabase}.accounts.id, 'und', 0, #{mydatabase}.accounts.last_name, NULL"
  sql +=  " FROM #{mydatabase}.accounts"
  sql +=  " WHERE #{mydatabase}.accounts.type = 'User'"
  sql +=  " ON DUPLICATE KEY UPDATE field_last_name_value=#{mydatabase}.accounts.last_name"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal users last name table: #{err}"
    return false
  end
  puts "finished user last name data table replacement."

  puts "starting user last name revisions table replacement..."
  sql = "INSERT INTO #{drupaldatabase}.field_revision_field_last_name (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_last_name_value, field_last_name_format)"
  sql +=  " SELECT 'user', 'user', 0, #{mydatabase}.accounts.id, #{mydatabase}.accounts.id, 'und', 0, #{mydatabase}.accounts.last_name, NULL"
  sql +=  " FROM #{mydatabase}.accounts"
  sql +=  " WHERE #{mydatabase}.accounts.type = 'User'"
  sql +=  " ON DUPLICATE KEY UPDATE field_last_name_value=#{mydatabase}.accounts.last_name"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal users last name revisions table: #{err}"
    return false
  end
  puts "finished user last name revisions table replacement."
    
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
  
  #  truncate first
  begin
    result = connection.execute("TRUNCATE TABLE  #{drupaldatabase}.og;")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table truncate: #{err}"
    return false
  end
  
  
  sql = "INSERT INTO #{drupaldatabase}.og (gid,etid,entity_type,label,state,created) SELECT #{mydatabase}.communities.drupal_node_id,#{mydatabase}.communities.drupal_node_id,'node',#{mydatabase}.communities.name,1,UNIX_TIMESTAMP() FROM #{mydatabase}.communities WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  puts "og table updated..."
  

  ####### # update the field_data_group_group table
  
  
  puts "updating the field_data_group_group table..."
  
  #  truncate first
  begin
    result = connection.execute("TRUNCATE TABLE  #{drupaldatabase}.field_data_group_group;")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the field_data_group_group table truncate: #{err}"
    return false
  end
  
  sql = "INSERT INTO #{drupaldatabase}.field_data_group_group (bundle,deleted,entity_id,revision_id,language,delta,group_group_value,entity_type) SELECT 'group',0, #{mydatabase}.communities.drupal_node_id,#{drupaldatabase}.node.vid,'und',0,1,'node' FROM #{mydatabase}.communities, #{drupaldatabase}.node WHERE #{drupaldatabase}.node.nid = #{mydatabase}.communities.drupal_node_id and #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL;"
  
  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the field_data_group_group table update: #{err}"
    return false
  end
  
  puts "field_data_group_group table updated..."

  ####### # update the field_revision_group_group table
  
  
  puts "updating the field_revision_group_group table..."
  
  #  truncate first
  begin
    result = connection.execute("TRUNCATE TABLE  #{drupaldatabase}.field_revision_group_group;")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the field_revision_group_group table truncate: #{err}"
    return false
  end

  # duplicate of field_data_group_group
  sql = "INSERT INTO #{drupaldatabase}.field_revision_group_group SELECT * from #{drupaldatabase}.field_data_group_group"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the field_revision_group_group table update: #{err}"
    return false
  end
  
  puts "field_revision_group_group table updated..."


  # group designation
  puts "starting droup designation data table replacement..."
  sql = "INSERT INTO #{drupaldatabase}.field_data_field_group_designation (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_group_designation_value)"
  sql +=  " SELECT 'node', 'group', 0, #{mydatabase}.communities.drupal_node_id, #{mydatabase}.communities.drupal_node_id, 'und', 0, #{mydatabase}.communities.entrytype"
  sql +=  " FROM #{mydatabase}.communities"
  sql +=  " WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL"
  sql +=  " ON DUPLICATE KEY UPDATE field_group_designation_value=#{mydatabase}.communities.entrytype"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal group designation field data: #{err}"
    return false
  end
  puts "finished user drupal group designation field data table replacement."


  puts "starting droup designation revision table replacement..."
  sql = "INSERT INTO #{drupaldatabase}.field_revision_field_group_designation (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_group_designation_value)"
  sql +=  " SELECT 'node', 'group', 0, #{mydatabase}.communities.drupal_node_id, #{mydatabase}.communities.drupal_node_id, 'und', 0, #{mydatabase}.communities.entrytype"
  sql +=  " FROM #{mydatabase}.communities"
  sql +=  " WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL"
  sql +=  " ON DUPLICATE KEY UPDATE field_group_designation_value=#{mydatabase}.communities.entrytype"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during replacement of the drupal group designation field revision: #{err}"
    return false
  end
  puts "finished user drupal group designation field revision table replacement."



  ####### # delete current memberships
    
  #  truncate first
  begin
    result = connection.execute("TRUNCATE TABLE  #{drupaldatabase}.og_users_roles;")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  #  truncate first
  begin
    result = connection.execute("DELETE FROM  #{drupaldatabase}.field_data_group_audience WHERE #{drupaldatabase}.field_data_group_audience.entity_type = 'user';")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  
  #  truncate first
  begin
    result = connection.execute("DELETE FROM  #{drupaldatabase}.og_membership WHERE #{drupaldatabase}.og_memberrship.entity_type = 'user';")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the deletion of old records in og_membership table: #{err}"
    return false
  end
  
  #  truncate first
  begin
    result = connection.execute("DELETE FROM  #{drupaldatabase}.field_revision_group_audience WHERE #{drupaldatabase}.field_revision_group_audience.entity_type = 'user';")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og table update: #{err}"
    return false
  end
  
  ####### # set current memberships - og_users_roles
  
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
  
  ####### # set current memberships - field_data_group_audience
  
  puts "creating managed memberships in the field_data_group_audience table..."

  # etid is field_config_entity_type for 'user' == 3 - hardcoded!  
  
  # Note: delta is a hack! there's an primary index on etid+revision_id+deleted+delta+langague and since revision_id == the uid, this means that
  # every user row gets an incremented delta.  Trying to query on this and insert is a hard problem(tm) (it can be done with max(delta), but you
  # have to make a couple of passes, and I haven't figured it out yet.  So, I'm setting delta to the gid.  I don't think delta is used in the queries)
  

  sql = "INSERT INTO #{drupaldatabase}.field_data_group_audience (bundle,deleted,entity_id,revision_id,language,delta,group_audience_gid,group_audience_state,group_audience_created,entity_type) SELECT 'user',0, #{mydatabase}.communityconnections.user_id,#{mydatabase}.communityconnections.user_id,'und',#{drupaldatabase}.og.gid,#{drupaldatabase}.og.gid,1,UNIX_TIMESTAMP(#{mydatabase}.communityconnections.created_at),'user' FROM #{drupaldatabase}.og, #{mydatabase}.communities, #{mydatabase}.communityconnections WHERE #{drupaldatabase}.og.etid = #{mydatabase}.communities.drupal_node_id AND #{mydatabase}.communities.id = #{mydatabase}.communityconnections.community_id AND #{mydatabase}.communityconnections.connectiontype IN ('leader','member') AND #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL;"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the field_data_group_audience creation: #{err}"
    return false
  end
  
  puts "field_data_group_audience managed memberships created..."
  
  ####### # set current memberships - field_revision_group_audience

  puts "creating managed memberships in the field_revision_group_audience table..."

  # duplicate of field_data_group_audience
  sql = "INSERT INTO #{drupaldatabase}.field_revision_group_audience SELECT * from #{drupaldatabase}.field_data_group_audience where entity_type = 'user'"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the field_revision_group_audience creation: #{err}"
    return false
  end
  
  puts "field_revision_group_audience managed memberships created..."
  
  
  
####### # set current memberships - og_membership
  
  puts "creating managed memberships in the og_membership table..."

  sql = "INSERT INTO #{drupaldatabase}.og_membership (name, etid, entity_type, gid, state, created) SELECT 'og_membership_type_default', #{mydatabase}.communityconnections.user_id, 'user',#{drupaldatabase}.og.gid, '1', UNIX_TIMESTAMP(#{mydatabase}.communityconnections.created_at) FROM #{drupaldatabase}.og, #{mydatabase}.communities, #{mydatabase}.communityconnections WHERE #{drupaldatabase}.og.etid = #{mydatabase}.communities.drupal_node_id AND #{mydatabase}.communities.id = #{mydatabase}.communityconnections.community_id AND #{mydatabase}.communityconnections.connectiontype IN ('leader','member') AND #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL;"

  # execute the sql
  begin
    result = connection.execute(sql)
  rescue => err
    $stderr.puts "ERROR: Exception raised during the og_membership creation: #{err}"
    return false
  end
  
  puts "og_membership managed memberships created..."
  
  
  ####### # finally - dump cache_field
  
  # execute the sql
  begin
    result = connection.execute("TRUNCATE table #{drupaldatabase}.cache_field;")
  rescue => err
    $stderr.puts "ERROR: Exception raised during the field_revision_group_audience creation: #{err}"
    return false
  end
end

def update_group_resource_tags(connection,drupaldatabase)
  puts "updating group resource tags..."
  
  # build my insert query
  communities = Community.public_list.all(:order => 'name')
  insert_values = []
  communities.each do |community|
    next if !community.connect_to_drupal
    next if community.drupal_node_id.blank?
    next if community.cached_content_tags(true).blank?
    community.cached_content_tags.each do |content_tag|
      if(content_tag == community.primary_content_tag_name)
        primary = 1
      else
        primary = 0
      end
      insert_values << "(#{community.drupal_node_id},#{ActiveRecord::Base.quote_value(community.name)},#{community.id},#{ActiveRecord::Base.quote_value(content_tag)},#{primary})"
    end
  end
  
  if(!insert_values.blank?)
    insert_sql = "INSERT INTO #{drupaldatabase}.group_resource_tags (nid,community_name,community_id,resource_tag_name,is_primary_tag)"
    insert_sql += " VALUES #{insert_values.join(',')}"
    
    # truncate first, insert second
    begin
      result = connection.execute("TRUNCATE TABLE  #{drupaldatabase}.group_resource_tags;")
    rescue => err
      $stderr.puts "ERROR: Exception raised during the group_resource_tags table truncate: #{err}"
      return false
    end
    
    # execute the sql
    begin
      result = connection.execute(insert_sql)
    rescue => err
      $stderr.puts "ERROR: Exception raised during the group_resource_tags insertion: #{err}"
      return false
    end
  end
  return true;
  
end



#################################
# Main

# my database connection 
mydatabase = User.connection.instance_variable_get("@config")[:database]
# replace/insert user accounts
result = update_from_darmok_users(User.connection,@drupaldatabase,mydatabase)
# new groups
result = new_groups_from_darmok_communities(Community.connection,@drupaldatabase,mydatabase)
# groups update
result = update_groups_from_darmok_communities(Community.connection,@drupaldatabase,mydatabase)
# group resource tags
result = update_group_resource_tags(Community.connection,@drupaldatabase)