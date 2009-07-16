class MigratePubsiteInstitutions < ActiveRecord::Migration
  def self.up
    
    # add domain string and shared flag
    add_column(:institutions, :public_uri, :string )
    add_column(:institutions, :referer_domain, :string )
    add_column(:institutions, :shared_logo, :boolean, :default => 0)
    add_column(:institutions, :show_in_public_list, :boolean, :default => false)

    # copy data on code match
    institution_sql = "UPDATE institutions, pubsite_institutions"
    institution_sql += " SET institutions.public_uri = pubsite_institutions.uri, institutions.referer_domain = pubsite_institutions.domain,"
    institution_sql += " institutions.shared_logo = pubsite_institutions.shared, institutions.show_in_public_list = 1"
    institution_sql += " WHERE institutions.code = pubsite_institutions.code"    
    execute "#{institution_sql}"
    
    # university of california doesn't match up (no code) - do by hand
    execute "UPDATE institutions, pubsite_institutions SET institutions.public_uri = pubsite_institutions.uri, institutions.referer_domain = pubsite_institutions.domain, institutions.shared_logo = pubsite_institutions.shared WHERE institutions.name = 'University of California' and pubsite_institutions.name = 'University of California' "

    # index referer_domain
    add_index(:institutions, ["referer_domain"])
    
    # bonus, clear institutional team settings, I dropped those a few weeks ago
    execute "UPDATE institutions SET institutionalteam_id = 0"
    
    drop_table(:pubsite_institutions)
    
    
  end

  def self.down
  end
end
