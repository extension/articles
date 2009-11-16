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
    
    # user model changes
    remove_column :users, :is_staff  # not really related, just some cleanup while here
    add_column :users, "temp_institution_id", :integer, :default => 0
    add_column :users, "temp_organization_name", :string
    add_column :users, "temp_organization_name_typed", :string
    add_column :users, :additionaldata, :text  # serialized field
        
    
    # removing the 1994 and a few other land grants for now,
    institutions_to_delete = []
    institutions_to_delete <<  'Bay Mills Community College'
    institutions_to_delete <<  'Blackfeet Community College'
    institutions_to_delete <<  'Candeska Cikana Community College'
    institutions_to_delete <<  'Chief Dull Knife College'
    institutions_to_delete <<  'College of the Menominee Nation'
    institutions_to_delete <<  'Crownpoint Institute of Technology'
    institutions_to_delete <<  'D-Q University'
    institutions_to_delete <<  'Dine College'
    institutions_to_delete <<  'Fond du Lac Tribal & Community College'
    institutions_to_delete <<  'Fort Belknap College'
    institutions_to_delete <<  'Fort Berthold Community College'
    institutions_to_delete <<  'Fort Peck Community College'
    institutions_to_delete <<  'Haskell Indian Nations University'
    institutions_to_delete <<  'Institute of American Indian Arts'
    institutions_to_delete <<  'Lac Courte Oreilles Ojibwa Community College'
    institutions_to_delete <<  'Leech Lake Tribal College'
    institutions_to_delete <<  'Little Big Horn College'
    institutions_to_delete <<  'Little Priest Tribal College'
    institutions_to_delete <<  'Nebraska Indian Community College'
    institutions_to_delete <<  'Northwest Indian College'
    institutions_to_delete <<  'Oglala Lakota College'
    institutions_to_delete <<  'Saginaw Chippewa Tribal College'
    institutions_to_delete <<  'Salish Kootenai College'
    institutions_to_delete <<  'Sinte Gleska University'
    institutions_to_delete <<  'Sisseton Wahpeton Community College'
    institutions_to_delete <<  'Si Tanka University'
    institutions_to_delete <<  'Sitting Bull College'
    institutions_to_delete <<  'Southwestern Indian Polytechnic Institute'
    institutions_to_delete <<  'Stone Child College'
    institutions_to_delete <<  'Turtle Mountain Community College'
    institutions_to_delete <<  'United Tribes Technical College'
    institutions_to_delete <<  'White Earth Tribal and Community College'
    # these two are empty
    institutions_to_delete <<  'American Samoa Community College'
    institutions_to_delete <<  'Northern Marianas College'
      
    institutions_to_delete.each do |i|
      execute "DELETE from institutions where institutions.name = '#{i}'"
    end
    
    # rename institutions table
    rename_table('institutions', 'old_institutions')
    
    # originally typed organizational name
    execute "UPDATE users, old_institutions SET users.temp_organization_name_typed = old_institutions.name WHERE users.institution_id = old_institutions.id"
    
    # if institution is blank ('') - then clear it of users model
    execute "UPDATE users, old_institutions SET users.institution_id = 0 WHERE users.institution_id = old_institutions.id and old_institutions.name = ''"
    
    # clean up NIFA and USDA unless the user address ends in .gov
    execute "UPDATE users, old_institutions SET users.institution_id = 0 WHERE users.institution_id = old_institutions.id and old_institutions.name IN ('NIFA','USDA') and users.email NOT LIKE '%.gov%'"
    
    # change referers to match better the domain
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'unl.edu' WHERE old_institutions.referer_domain = 'nebraska.edu'"     
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'uwex.edu' WHERE old_institutions.referer_domain = 'wisc.edu'"      
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'utk.edu' WHERE old_institutions.referer_domain = 'tennessee.edu'"     
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'ksu.edu' WHERE old_institutions.referer_domain = 'k-state.edu'"    
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'maine.edu' WHERE  old_institutions.referer_domain = 'umaine.edu'"      
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'uaex.edu' WHERE old_institutions.referer_domain = 'uark.edu'"    
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'uaf.edu' WHERE old_institutions.referer_domain = 'alaska.edu'"    
    execute "UPDATE old_institutions SET old_institutions.referer_domain = 'luresext.edu' WHERE old_institutions.referer_domain = 'lunet.edu'"    
    
    # do email matching except for tamu.edu
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE CONCAT('%', old_institutions.referer_domain) and users.email NOT LIKE '%tamu.edu'"
    
    # special case for lsu.edu and suagcenter.com people
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%lsu.edu' and old_institutions.name LIKE 'Louisiana State University'"
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%suagcenter.com' and old_institutions.name LIKE 'Southern University A&M College'"

    # special case for illinois
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%illinois.edu' and old_institutions.name LIKE 'University of Illinois'"
    
    # special case for Alaska
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%alaska.edu' and old_institutions.name LIKE 'University of Alaska'"
    
    # special case for wisconsin
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%wisc.edu' and old_institutions.name LIKE 'University of Wisconsin'"
            
    # USDA then NIFA/CSREES, order matters
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%usda.gov' and old_institutions.name LIKE 'USDA'"    
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%csrees.usda.gov' and old_institutions.name LIKE 'NIFA'"
    execute "UPDATE users, old_institutions SET users.institution_id = old_institutions.id WHERE users.email LIKE '%nifa.usda.gov' and old_institutions.name LIKE 'NIFA'"
    
    # change location for NIFA and USDA to DC
    execute "UPDATE old_institutions SET old_institutions.location_id = 17 WHERE old_institutions.name LIKE 'USDA'"    
    execute "UPDATE old_institutions SET old_institutions.location_id = 17 WHERE old_institutions.name LIKE 'NIFA'"    
    
    # expand NIFA name
    execute "UPDATE old_institutions SET old_institutions.name = 'National Institute of Food and Agriculture' WHERE old_institutions.name LIKE 'NIFA'"    
            
    # get originally typed - or more likely - the email modified organization name back into user model
    execute "UPDATE users, old_institutions SET users.temp_organization_name = old_institutions.name WHERE users.institution_id = old_institutions.id"
    
    # create official institution communities from old_institutions table from the landgrant and federal institutions
    execute "INSERT INTO communities (entrytype,memberfilter,name,created_at,updated_at,created_by,uri,location_id,public_uri,referer_domain,shared_logo,show_in_public_list,institution_code) SELECT 3,1,name,created_at,updated_at,1,uri,location_id,public_uri,referer_domain,shared_logo,show_in_public_list,code FROM old_institutions WHERE old_institutions.entrytype IN (1,3)"
    
    # set primary institution id based on a name match to the newly imported communities
    execute "UPDATE users,communities SET users.temp_institution_id = communities.id WHERE users.temp_organization_name = communities.name AND communities.entrytype = 3"        
  
    # finally, create community connection records for these
    execute "INSERT INTO communityconnections (user_id,community_id,connectiontype,connectioncode,connected_by,created_at,updated_at) SELECT id,temp_institution_id,'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and temp_institution_id !=0 and temp_institution_id IS NOT NULL"  

    # clear out the organization names for those we just added, to make it easier to create additional migrations later - we don't need to keep that data
    execute "UPDATE users SET users.temp_organization_name = '' WHERE temp_institution_id !=0 and temp_institution_id IS NOT NULL "        
            
    #####  Texas Institutions, California, and Colorado State
    Community.reset_column_information  
    
    # insert statement
    insert_statement = "INSERT IGNORE INTO communityconnections (user_id,community_id,connectiontype,connectioncode,connected_by,created_at,updated_at)"
   
    # create an official institution for Texas AgriLife Research
    research = Community.create(:entrytype => Community::INSTITUTION, :created_by => User.systemuserid, :location_id => 53, :name => 'Texas AgriLife Research')
    # add users to the new research community
    research_select = "SELECT id,#{research.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and temp_organization_name ="
    research_orgs = []
    research_orgs << 'Texas AgriLife Research'
    research_orgs << 'Texas A&M University'
    research_orgs << 'Texas A&M'
    research_orgs << 'Texas Agricultural Experiment Station'
    research_orgs << 'AgriLife Research'
   
   
    research_orgs.each do |org|
      execute "#{insert_statement} #{research_select} '#{org}'"
    end
   
    # get Texas AgriLife Extension community - change the name
    agrilife = Community.find_by_name('Texas AgriLife Extension')
    agrilife.update_attribute(:name,'Texas AgriLife Extension Service')
   
    # add users to the new research community
    agrilife_select = "SELECT id,#{agrilife.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and temp_organization_name ="
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
    agrilife_orgs << 'AgriLife Extension Service'
    agrilife_orgs << 'Texas A&M Agrilife'
    agrilife_orgs << 'TAMU'
   
    agrilife_orgs.each do |org|
      execute "#{insert_statement} #{agrilife_select} '#{org}'"
    end
  
    # colorado
    colorado = Community.find_by_name('Colorado State University')       
    colorado_select = "SELECT id,#{colorado.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and temp_organization_name LIKE '%Colorado State%'"
    execute "#{insert_statement} #{colorado_select}"

    # california
    california = Community.find_by_name('University of California')       
    california_select = "SELECT id,#{california.id},'member',#{Communityconnection::PRIMARY},1,created_at,NOW() from users WHERE retired = 0 and vouched = 1 and temp_organization_name LIKE '%University of California%'"
    execute "#{insert_statement} #{california_select}"
    
    # set additional data
    execute "UPDATE users set additionaldata = CONCAT('--- \n:signup_affiliation: Working with ', temp_organization_name_typed, '\n') where temp_organization_name_typed IS NOT NULL and temp_organization_name_typed != ''"
   
    # drop temporary institution id
    remove_column :users, "institution_id"
    remove_column :users, "temp_institution_id"
    remove_column :users, "temp_organization_name"
    remove_column :users, "temp_organization_name_typed"
    
    # finally, copy institution name to public name so that it can be edited later if necessary
    execute "UPDATE communities SET communities.public_name = communities.name WHERE communities.entrytype = 3"
  end
  

  def self.down
  end
end
