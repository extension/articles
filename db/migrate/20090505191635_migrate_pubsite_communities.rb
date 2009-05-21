class MigratePubsiteCommunities < ActiveRecord::Migration
  def self.up
    #
    # PLEASE NOTE:  This migration will need to be reviewed before launch to deal with any community name changes 
    # and any new communities that have been added to the pubsite application.
    #
    
    # add public_name, public_description, and is_launched columns to communities
    add_column(:communities, :public_name, :string )
    add_column(:communities, :public_description, :text)
    add_column(:communities, :is_launched, :boolean, :default => 0)
    add_column(:communities, :public_topic_id, :integer)
    
    # mappings - consist of pubsite_communities.name to communities.id
    # name is left to make this more readable
    # id is used to not have to deal with name changes in People by launch day
    community_mappings = {}
    community_mappings['Horses'] = 10
    community_mappings['Entrepreneurs & Their Communities'] = 7
    community_mappings['Gardens, Lawns & Landscapes'] = 2
    community_mappings['Imported Fire Ants'] = 11
    community_mappings['Personal Finance'] = 21
    community_mappings['Agrosecurity and Floods'] = 8
    community_mappings['Beef Cattle'] = 1
    community_mappings['Family Caregiving'] = 9
    community_mappings['Diversity Across Higher Education'] = 6
    community_mappings['Pesticide Environmental Stewardship'] = 15
    community_mappings['Organic Agriculture'] = 20
    community_mappings['Science, Engineering, and Technology for Youth'] = 19
    community_mappings['Wildlife Damage Management'] = 18
    community_mappings['Corn and Soybean Production'] = 3
    community_mappings['Cotton'] = 4
    community_mappings['Dairy'] = 5
    community_mappings['Geospatial Technology'] = 14
    community_mappings['Urban Integrated Pest Management'] = 17
    community_mappings['Pork Information'] = 16
    community_mappings['Animal Manure Management'] = 13
    community_mappings['Parenting'] = 12
    # "managing in tough times community"
    community_mappings['Financial Crisis'] = 193
    community_mappings['Goats'] = 26
    community_mappings['Small Meat Processors'] = 29
    community_mappings['Pest Management In and Around Structures'] = 17
    
    
    # loop through the list and run update statements - yes, 24 queries is a lot, but...
    community_mappings.each do |name,id|
      sqlstring = "UPDATE communities,pubsite_communities"
      sqlstring += " SET communities.public_name = pubsite_communities.name,"
      sqlstring += " communities.public_description = pubsite_communities.description,"
      sqlstring += " communities.is_launched = pubsite_communities.visible,"
      sqlstring += " communities.public_topic_id = pubsite_communities.topic_id"
      sqlstring += " WHERE pubsite_communities.name = '#{name}'"
      sqlstring += " AND communities.id = #{id}"  
      execute sqlstring
    end
    
    # before we drop the table, update the community id in the pubsite tags table
    community_mappings.each do |name,id|
      sqlstring = "UPDATE pubsite_tags,pubsite_communities"
      sqlstring += " SET pubsite_tags.community_id = #{id}"
      sqlstring += " WHERE pubsite_communities.name = '#{name}'"
      sqlstring += " AND pubsite_tags.community_id = pubsite_communities.id"  
      execute sqlstring
    end
    
    drop_table(:pubsite_communities)
    
  end

  def self.down
    # no going back!
  end
end
