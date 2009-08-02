class CreatePrimaryContentTag < ActiveRecord::Migration
  def self.up    
    # this is about to be quite the exercise
    # communities with more than one tag currently - number is community.id
    fixcommunities = {}
    fixcommunities[19] = 'science,engineering,technology' # youthset
    fixcommunities[8] = 'disasters,biosecurity' # eden
    fixcommunities[13] = 'animal manure management,animalmanure' #lpelc/animal manure management
    
    Community.all.each do |c|
      if(!fixcommunities[c.id].nil?)
        c.content_tag_names=(fixcommunities[c.id])
      else
        content_tags = c.tags_by_ownerid_and_kind(User.systemuserid,Tag::CONTENT)
        if(!content_tags.blank?)
          c.content_tag_names=(content_tags.map(&:name))
        end
      end
    end
    
  end

  def self.down
  end
end
