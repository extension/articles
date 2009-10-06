class ModifyInstitutionsAndCommunities < ActiveRecord::Migration
  def self.up
    # cleanup
    remove_column :communities, :open
    remove_column :communities, :listeligible
    remove_column :institutions, :location_abbreviation
    
    # description for institutions
    add_column :institutions, :description, :text
    add_column :users, :organization, :string
    
    # data cleanup
    # if institution is blank ('') - then clear it of users model
    execute "UPDATE users, institutions SET users.institution_id = 0 WHERE users.institution_id = institutions.id and institutions.name = ''"
    # get originally typed organization name back into user model
    execute "UPDATE users, institutions SET users.organization = institutions.name WHERE users.institution_id = institutions.id"
    # clear out state and user-created institution settings
    execute "UPDATE users, institutions SET users.institution_id = 0 WHERE users.institution_id = institutions.id and institutions.entrytype IN (2,4)"
    # finally, get rid of the state institutions and the user-created institutions
    execute "DELETE FROM institutions WHERE entrytype IN (2,4)"
  end

  def self.down
  end
end




