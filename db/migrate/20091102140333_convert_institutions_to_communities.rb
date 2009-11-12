class ConvertInstitutionsToCommunities < ActiveRecord::Migration
  def self.up
    # cleanup
    remove_column :communities, :open
    remove_column :communities, :listeligible
    # create needed institution columns and indexes inside the communities table
    add_column :communities, "location_id", :integer, :default => 0
    add_column :communities, "public_uri", :string    
    add_column :communities, "shared_logo", :boolean, :default => false
    add_column :communities, "referer_domain", :string
    add_column :communities, "institution_code", :string, :limit => 10
    add_column :communities, "logo_id", :integer, :default => 0

    add_index "communities", ["referer_domain"]
    
    # add originally typed organization name to user model
    add_column :users, "temp_institution_id", :integer, :default => 0
    add_column :users, "organization_entrytype", :integer, :default => 0
    add_column :users, "organization_name", :string
    
    # rename institutions table
    rename_table('institutions', 'old_institutions')
    
    # if institution is blank ('') - then clear it of users model
    execute "UPDATE users, old_institutions SET users.institution_id = 0 WHERE users.institution_id = old_institutions.id and old_institutions.name = ''"
    # get originally typed organization name back into user model
    execute "UPDATE users, old_institutions SET users.organization_name = old_institutions.name, users.organization_entrytype = old_institutions.entrytype WHERE users.institution_id = old_institutions.id"
    
    # create official institution communities from old_institutions table from the landgrant and federal institutions
    execute "INSERT INTO communities (entrytype,memberfilter,name,created_at,updated_at,created_by,uri,location_id,public_uri,referer_domain,shared_logo,show_in_public_list,institution_code) SELECT 3,1,name,created_at,updated_at,1,uri,location_id,public_uri,referer_domain,shared_logo,show_in_public_list,code FROM old_institutions WHERE old_institutions.entrytype IN (1,3)"
    
    # set primary institution id based on a name match to the newly imported communities
    execute "UPDATE users,communities SET users.temp_institution_id = communities.id WHERE users.organization_name = communities.name AND communities.entrytype = 3"        
  
    # finally, create community connection records for these
    execute "INSERT INTO communityconnections (user_id,community_id,connectiontype,connectioncode,connected_by,created_at,updated_at) SELECT id,temp_institution_id,'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and temp_institution_id !=0 and temp_institution_id IS NOT NULL"  

    # clear out the organization names for those we just added, to make it easier to create additional migrations later - we don't need to keep that data
    execute "UPDATE users SET users.organization_name = '', users.organization_entrytype = 0 WHERE temp_institution_id !=0 and temp_institution_id IS NOT NULL "        
        
    # drop temporary institution id
    remove_column :users, "temp_institution_id"
    
    
  end

  def self.down
  end
end
