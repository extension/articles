class NormalizeTexasInstitutions < ActiveRecord::Migration
  def self.up
    # create an official institution for Texas AgriLife Research
    research = Community.create(:entrytype => Community::INSTITUTION, :created_by => User.systemuserid, :location_id => 53, :name => 'Texas AgriLife Research')
    
    # add users to the new research community
    corequerystring = "INSERT IGNORE INTO communityconnections (user_id,community_id,connectiontype,connectioncode,connected_by,created_at,updated_at) SELECT id,#{research.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and organization_name ="
    execute "#{corequerystring} 'Texas AgriLife Research'"
    execute "#{corequerystring} 'Texas A&M University'"
    execute "#{corequerystring} 'Texas A&M'"
    execute "#{corequerystring} 'Texas Agricultural Experiment Station'"

    # get Texas AgriLife Extension community - change the name
    agrilife = Community.find_by_name('Texas AgriLife Extension')
    agrilife.update_attribute(:name,'Texas AgriLife Extension Service')
    
    # add users to the new research community
    corequerystring = "INSERT IGNORE INTO communityconnections (user_id,community_id,connectiontype,connectioncode,connected_by,created_at,updated_at) SELECT id,#{agrilife.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and organization_name ="
    execute "#{corequerystring} 'Texas Agrilife Extension Service'"
    execute "#{corequerystring} 'Texas A&M University - Texas AgriLife Extension'"
    execute "#{corequerystring} 'Texas AgriLife'"
    execute "#{corequerystring} 'Texas AgriLife Extension/Research'"
    execute "#{corequerystring} 'AgriLife Extension, Texas A&M University'"
    execute "#{corequerystring} 'Texas AgriLife Extension Service District'"
    execute "#{corequerystring} 'Texas AgriLife Extension Service/Agricultural & Environmental Safety'"
    execute "#{corequerystring} 'Texas AgriLife Extension Services'"
    execute "#{corequerystring} 'Texas AgriLife Res & Ext Center'"
    execute "#{corequerystring} 'Texas AgriLife Research & Extension Center, Dallas'"
    execute "#{corequerystring} 'Texas A&M University System'"
    execute "#{corequerystring} 'Texas Cooperative Extension'"
  end

  def self.down
  end
end
