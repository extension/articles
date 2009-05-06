class RenormalizeTags < ActiveRecord::Migration
  def self.up

     # first things first, go through all the taggings that have a space in them, group them up by a tag
     # and update the tag name the tag_display - which will re-trigger normalization
     # we have to do this in active record, because mysql has no regex-based "replace"
     # Note - don't "include :tag" - it takes 82.0742s in dev
     # "include tag" - it takes 4.0164s in dev
     taggings = Tagging.all(:include => :tag, :conditions => "tag_display REGEXP ' '", :group => "tag_id")
     taggings.each do |t|
       t.tag.update_attribute(:name,t.tag_display)
     end
     
     # now, find all the underscore tags that are equivalent to space tags when underscores are converted to spaces, and reassociate the taggings
     execute "UPDATE taggings, (SELECT id as tagid,name as tagname,utid,utname FROM tags, (select id as utid,name as utname FROM tags WHERE name REGEXP '_') as underscore_tags WHERE tags.name = REPLACE(underscore_tags.utname,'_',' ')) as underscore_to_space SET taggings.tag_id = tagid WHERE taggings.tag_id = utid"
     
     # now, delete all the underscore tags that will result in a duplicate tag row
     execute "DELETE tags.* from tags, (SELECT id as tagid,name as tagname,utid,utname FROM tags, (select id as utid,name as utname FROM tags WHERE name REGEXP '_') as underscore_tags WHERE tags.name = REPLACE(underscore_tags.utname,'_',' ')) as underscore_to_space WHERE tags.id = utid"

     # now, convert the rest to spaces
     execute "UPDATE tags SET tags.name = REPLACE(tags.name,'_',' ') WHERE tags.name REGEXP '_'"
     
  end

  def self.down
  end
end
