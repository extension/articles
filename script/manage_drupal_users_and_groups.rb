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

def execute_sql(activity,sqlstring)
  was_success = true # assume success
  benchmark = Benchmark.measure do
    begin
      result = User.connection.execute(sqlstring)
    rescue => err
      $stderr.puts "ERROR: Exception raised sql execution for #{activity} : #{err}"
      was_success = false
    end
  end
  
  if(was_success)
    puts "#{activity} : #{benchmark.real.round(2)}s"
  end

end

  
  
def update_from_darmok_users(drupaldatabase,mydatabase)
  passwordstring = AppConfig.configtable['passwordstring']
  
  ## user table replacement
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.users (uid,name,pass,mail,created,status)
   SELECT #{mydatabase}.accounts.id, #{mydatabase}.accounts.login,'#{passwordstring}', #{mydatabase}.accounts.email,UNIX_TIMESTAMP(#{mydatabase}.accounts.created_at),(NOT(#{mydatabase}.accounts.retired) AND (#{mydatabase}.accounts.vouched))
   FROM #{mydatabase}.accounts
   WHERE #{mydatabase}.accounts.type = 'User'
   ON DUPLICATE KEY UPDATE name=#{mydatabase}.accounts.login, pass='#{passwordstring}',mail=#{mydatabase}.accounts.email,status=(NOT(#{mydatabase}.accounts.retired) AND (#{mydatabase}.accounts.vouched))
  END_SQL

  execute_sql('user table replacement', sql)

  ## admin roles replacement, delete and insert
  sql = "DELETE from #{drupaldatabase}.users_roles where rid = #{ADMIN_ROLE}"
  execute_sql('admin role deletion', sql)
  
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.users_roles (uid,rid)
    SELECT #{drupaldatabase}.users.uid, 3
    FROM #{mydatabase}.accounts,#{drupaldatabase}.users
    WHERE #{mydatabase}.accounts.is_admin = 1
    AND #{mydatabase}.accounts.id = #{drupaldatabase}.users.uid
  END_SQL
  execute_sql('admin role insertion', sql)
  
  
  ## first names
  datasql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.field_data_field_first_name (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_first_name_value, field_first_name_format)
    SELECT 'user', 'user', 0, #{mydatabase}.accounts.id, #{mydatabase}.accounts.id, 'und', 0, #{mydatabase}.accounts.first_name, NULL
    FROM #{mydatabase}.accounts
    WHERE #{mydatabase}.accounts.type = 'User'
    ON DUPLICATE KEY UPDATE field_first_name_value=#{mydatabase}.accounts.first_name
  END_SQL
  
  revisionsql = datasql.gsub('field_data_field_first_name','field_revision_field_first_name')
  execute_sql('first name replacement - data', datasql)
  execute_sql('first name replacement - revision', revisionsql)

  ## last names
  datasql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.field_data_field_last_name (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_last_name_value, field_last_name_format)
    SELECT 'user', 'user', 0, #{mydatabase}.accounts.id, #{mydatabase}.accounts.id, 'und', 0, #{mydatabase}.accounts.last_name, NULL
    FROM #{mydatabase}.accounts
    WHERE #{mydatabase}.accounts.type = 'User'
    ON DUPLICATE KEY UPDATE field_last_name_value=#{mydatabase}.accounts.last_name
  END_SQL
  revisionsql = datasql.gsub('field_data_field_last_name','field_revision_field_last_name')
  execute_sql('last name replacement - data', datasql)
  execute_sql('last name replacement - revision', revisionsql)

  ## authmap table
  sql = "REPLACE INTO #{drupaldatabase}.authmap (aid,uid,authname,module) SELECT uid,uid,CONCAT('https://people.extension.org/',name), 'openid' FROM #{drupaldatabase}.users;"
  execute_sql('authmap table replacement', sql)
  return true
end


def new_groups_from_darmok_communities(drupaldatabase,mydatabase)
  
  ## node_revision insertion
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.node_revision (nid,uid,title,log,timestamp) 
    SELECT 0,1,#{mydatabase}.communities.name,'Added by synchronization script',UNIX_TIMESTAMP() 
    FROM #{mydatabase}.communities 
    WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NULL;
  END_SQL
  execute_sql('node_revision insertion', sql)
  
  ## node insertion
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.node (vid,type,language,title,uid,created,changed,promote) 
    SELECT vid,'group','und',#{drupaldatabase}.node_revision.title,1,UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1 
    FROM #{drupaldatabase}.node_revision 
    WHERE #{drupaldatabase}.node_revision.nid = 0 and #{drupaldatabase}.node_revision.log = 'Added by synchronization script';
  END_SQL
  execute_sql('node insertion', sql)
  

  ## set the node_revision node id based on name match
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{drupaldatabase}.node_revision,#{drupaldatabase}.node 
    SET #{drupaldatabase}.node_revision.nid = #{drupaldatabase}.node.nid 
    WHERE #{drupaldatabase}.node.vid = #{drupaldatabase}.node_revision.vid 
      AND #{drupaldatabase}.node.type = 'group' 
      AND #{drupaldatabase}.node_revision.title = #{drupaldatabase}.node.title;
  END_SQL
  execute_sql('node_revision nid update', sql)
  

  ## set the darmok community association based on name
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{mydatabase}.communities,#{drupaldatabase}.node 
    SET #{mydatabase}.communities.drupal_node_id = #{drupaldatabase}.node.nid 
    WHERE #{drupaldatabase}.node.type = 'group' 
      AND  #{mydatabase}.communities.name = CAST(#{drupaldatabase}.node.title AS CHAR CHARACTER SET utf8) COLLATE utf8_unicode_ci 
      AND #{mydatabase}.communities.drupal_node_id IS NULL;
  END_SQL
  execute_sql('darmok community drupal_node_id update', sql)
  return true
end


def update_groups_from_darmok_communities(drupaldatabase,mydatabase)
  
  ## update the nodes table
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{drupaldatabase}.node,#{mydatabase}.communities 
    SET #{drupaldatabase}.node.title = #{mydatabase}.communities.name,#{drupaldatabase}.node.uid = 1 
    WHERE #{drupaldatabase}.node.nid =  #{mydatabase}.communities.drupal_node_id 
      AND #{drupaldatabase}.node.type = 'group' 
      AND #{mydatabase}.communities.connect_to_drupal = 1;
  END_SQL
  execute_sql('node table update', sql)
  
  ## update revisions table
  sql = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{drupaldatabase}.node_revision,#{drupaldatabase}.node 
    SET #{drupaldatabase}.node_revision.title = #{drupaldatabase}.node.title,#{drupaldatabase}.node_revision.log = 'Updated by synchronization script',#{drupaldatabase}.node_revision.uid = 1 
    WHERE #{drupaldatabase}.node.vid = #{drupaldatabase}.node_revision.vid 
      AND #{drupaldatabase}.node.type = 'group'
      AND #{drupaldatabase}.node_revision.title != #{drupaldatabase}.node.title;
  END_SQL
  execute_sql('node_revision table update', sql)


  ## update the og table
  truncate_sql = "TRUNCATE TABLE  #{drupaldatabase}.og;"
  insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.og (gid,etid,entity_type,label,state,created) 
    SELECT #{mydatabase}.communities.drupal_node_id,#{mydatabase}.communities.drupal_node_id,'node',#{mydatabase}.communities.name,1,UNIX_TIMESTAMP() 
    FROM #{mydatabase}.communities 
    WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL;
  END_SQL
  execute_sql('og table truncation', truncate_sql)
  execute_sql('og table insertion', insert_sql)
  
  ## group fields
  data_truncate_sql = "TRUNCATE TABLE  #{drupaldatabase}.field_data_group_group;"
  data_insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.field_data_group_group (bundle,deleted,entity_id,revision_id,language,delta,group_group_value,entity_type) 
    SELECT 'group',0, #{mydatabase}.communities.drupal_node_id,#{drupaldatabase}.node.vid,'und',0,1,'node' 
    FROM #{mydatabase}.communities, #{drupaldatabase}.node 
    WHERE #{drupaldatabase}.node.nid = #{mydatabase}.communities.drupal_node_id 
      AND #{mydatabase}.communities.connect_to_drupal = 1 
      AND #{mydatabase}.communities.drupal_node_id IS NOT NULL;
  END_SQL
  revision_truncate_sql = "TRUNCATE TABLE  #{drupaldatabase}.field_revision_group_group;"
  revision_insert_sql = "INSERT INTO #{drupaldatabase}.field_revision_group_group SELECT * from #{drupaldatabase}.field_data_group_group"
  execute_sql('group field truncation - data', data_truncate_sql)
  execute_sql('group field insertion - data', data_insert_sql)
  execute_sql('group field truncation - revision', revision_truncate_sql)
  execute_sql('group field insertion - revision', revision_insert_sql)
  
  ## group designation field
  data_sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.field_data_field_group_designation (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_group_designation_value)
    SELECT 'node', 'group', 0, #{mydatabase}.communities.drupal_node_id, #{mydatabase}.communities.drupal_node_id, 'und', 0, #{mydatabase}.communities.entrytype
    FROM #{mydatabase}.communities
    WHERE #{mydatabase}.communities.connect_to_drupal = 1 and #{mydatabase}.communities.drupal_node_id IS NOT NULL
    ON DUPLICATE KEY UPDATE field_group_designation_value=#{mydatabase}.communities.entrytype
  END_SQL
  revision_sql = data_sql.gsub("field_data_field_group_designation","field_revision_field_group_designation")
  execute_sql('group designation field replacement - data', data_sql)
  execute_sql('group designation field replacement - revision', revision_sql)
  
  ## memberships and roles
  
  # og_users_roles
  truncate_sql = "TRUNCATE TABLE  #{drupaldatabase}.og_users_roles;"
  # hardcoded roles - do not change these roles in drupal!!  leader = 3 member = 2
  insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.og_users_roles (uid,rid,gid) 
    SELECT #{mydatabase}.communityconnections.user_id,IF(#{mydatabase}.communityconnections.connectiontype = 'leader',3,2),#{drupaldatabase}.og.gid 
    FROM  #{drupaldatabase}.og, #{mydatabase}.communities, #{mydatabase}.communityconnections 
    WHERE #{drupaldatabase}.og.etid = #{mydatabase}.communities.drupal_node_id 
      AND #{mydatabase}.communities.id = #{mydatabase}.communityconnections.community_id 
      AND #{mydatabase}.communityconnections.connectiontype IN ('leader','member') 
      AND #{mydatabase}.communities.connect_to_drupal = 1 
      AND #{mydatabase}.communities.drupal_node_id IS NOT NULL;
  END_SQL
  execute_sql('og_users_roles truncation', truncate_sql)
  execute_sql('og_users_roles insertion', insert_sql)

  # group audience field
  # etid is field_config_entity_type for 'user' == 3 - hardcoded!  
  # Note: delta is a hack! there's an primary index on etid+revision_id+deleted+delta+langague and since revision_id == the uid, this means that
  # every user row gets an incremented delta.  Trying to query on this and insert is a hard problem(tm) (it can be done with max(delta), but you
  # have to make a couple of passes, and I haven't figured it out yet.  So, I'm setting delta to the gid.  I don't think delta is used in the queries)
  data_delete_sql = "DELETE FROM  #{drupaldatabase}.field_data_group_audience WHERE #{drupaldatabase}.field_data_group_audience.entity_type = 'user';"
  data_insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.field_data_group_audience (bundle,deleted,entity_id,revision_id,language,delta,group_audience_gid,group_audience_state,group_audience_created,entity_type) 
    SELECT 'user',0, #{mydatabase}.communityconnections.user_id,#{mydatabase}.communityconnections.user_id,'und',#{drupaldatabase}.og.gid,#{drupaldatabase}.og.gid,1,UNIX_TIMESTAMP(#{mydatabase}.communityconnections.created_at),'user' 
    FROM #{drupaldatabase}.og, #{mydatabase}.communities, #{mydatabase}.communityconnections 
    WHERE #{drupaldatabase}.og.etid = #{mydatabase}.communities.drupal_node_id 
      AND #{mydatabase}.communities.id = #{mydatabase}.communityconnections.community_id 
      AND #{mydatabase}.communityconnections.connectiontype IN ('leader','member') 
      AND #{mydatabase}.communities.connect_to_drupal = 1 
      AND #{mydatabase}.communities.drupal_node_id IS NOT NULL;
  END_SQL
  revision_delete_sql = "DELETE FROM  #{drupaldatabase}.field_revision_group_audience WHERE #{drupaldatabase}.field_revision_group_audience.entity_type = 'user';"
  revision_insert_sql = "INSERT INTO #{drupaldatabase}.field_revision_group_audience SELECT * from #{drupaldatabase}.field_data_group_audience where entity_type = 'user'"
  execute_sql('group audience field deletion - data', data_delete_sql)
  execute_sql('group audience field insertion - data', data_insert_sql)
  execute_sql('group audience field deletion - revision', revision_delete_sql)
  execute_sql('group audience field insertion - revision', revision_insert_sql)

  # og_membership
  delete_sql = "DELETE FROM  #{drupaldatabase}.og_membership WHERE #{drupaldatabase}.og_membership.entity_type = 'user';"
  insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{drupaldatabase}.og_membership (name, etid, entity_type, gid, state, created) 
    SELECT 'og_membership_type_default', #{mydatabase}.communityconnections.user_id, 'user',#{drupaldatabase}.og.gid, '1', UNIX_TIMESTAMP(#{mydatabase}.communityconnections.created_at)
    FROM #{drupaldatabase}.og, #{mydatabase}.communities, #{mydatabase}.communityconnections 
    WHERE #{drupaldatabase}.og.etid = #{mydatabase}.communities.drupal_node_id
      AND #{mydatabase}.communities.id = #{mydatabase}.communityconnections.community_id 
      AND #{mydatabase}.communityconnections.connectiontype IN ('leader','member') 
      AND #{mydatabase}.communities.connect_to_drupal = 1 
      AND #{mydatabase}.communities.drupal_node_id IS NOT NULL;
  END_SQL
  execute_sql('og_membership deletion', delete_sql)
  execute_sql('og_membership insertion', insert_sql)
end

def update_group_resource_tags(drupaldatabase)
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
    
    execute_sql('group_resource_tags trunction',"TRUNCATE TABLE  #{drupaldatabase}.group_resource_tags;")
    execute_sql('group_resource_tags insertion',insert_sql)
  end
  
  return true;
end


# my database connection 
mydatabase = User.connection.instance_variable_get("@config")[:database]
puts "\n## User Replacement and Insertion:"
update_from_darmok_users(@drupaldatabase,mydatabase)
puts "\n## New group creation:"
new_groups_from_darmok_communities(@drupaldatabase,mydatabase)
puts "\n## Existing groups update:"
update_groups_from_darmok_communities(@drupaldatabase,mydatabase)
puts "\n## Group resource tags update:"
update_group_resource_tags(@drupaldatabase)
puts "\n## Clearing the cache"
execute_sql('cache_field truncation', "TRUNCATE table #{@drupaldatabase}.cache_field;")

