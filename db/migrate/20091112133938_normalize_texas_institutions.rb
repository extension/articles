class NormalizeTexasInstitutions < ActiveRecord::Migration
  def self.up
    # insert statement
    insert_statement = "INSERT IGNORE INTO communityconnections (user_id,community_id,connectiontype,connectioncode,connected_by,created_at,updated_at)"
    
    # create an official institution for Texas AgriLife Research
    research = Community.create(:entrytype => Community::INSTITUTION, :created_by => User.systemuserid, :location_id => 53, :name => 'Texas AgriLife Research')
    # add users to the new research community
    research_select = "SELECT id,#{research.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and organization_name ="
    research_orgs = []
    research_orgs << 'Texas AgriLife Research'
    research_orgs << 'Texas A&M University'
    research_orgs << 'Texas A&M'
    research_orgs << 'Texas Agricultural Experiment Station'
    
    research_orgs.each do |org|
      execute "#{insert_statement} #{research_select} '#{org}'"
    end
    
    # get Texas AgriLife Extension community - change the name
    agrilife = Community.find_by_name('Texas AgriLife Extension')
    agrilife.update_attribute(:name,'Texas AgriLife Extension Service')
    
    # add users to the new research community
    agrilife_select = "SELECT id,#{agrilife.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and organization_name ="
    agrilife_orgs = []
    agrilife_orgs << 'Texas Agrilife Extension Service'
    agrilife_orgs << 'Texas A&M University - Texas AgriLife Extension'
    agrilife_orgs << 'Texas AgriLife'
    agrilife_orgs << 'Texas AgriLife Extension/Research'
    agrilife_orgs << 'AgriLife Extension, Texas A&M University'
    agrilife_orgs << 'Texas AgriLife Extension Service District'
    agrilife_orgs << 'Texas AgriLife Extension Service/Agricultural & Environmental Safety'
    agrilife_orgs << 'Texas AgriLife Extension Services'
    agrilife_orgs << 'Texas AgriLife Res & Ext Center'
    agrilife_orgs << 'Texas AgriLife Research & Extension Center, Dallas'
    agrilife_orgs << 'Texas A&M University System'
    agrilife_orgs << 'Texas Cooperative Extension'
    
    agrilife_orgs.each do |org|
      execute "#{insert_statement} #{agrilife_select} '#{org}'"
    end

    # okay, now for the people we just put into Institution buckets, get rid of their organization name and type
    # yes I know I could do a join and just one query, but this loop won't take long and it's easier to read
    research_orgs.each do |org|
      execute "UPDATE users SET users.organization_name = '', users.organization_entrytype = 0 WHERE users.organization_name = '#{org}'"        
    end
    
    agrilife_orgs.each do |org|
      execute "UPDATE users SET users.organization_name = '', users.organization_entrytype = 0 WHERE users.organization_name = '#{org}'"        
    end
    
  end

  def self.down
  end
end
