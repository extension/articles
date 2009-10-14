class ChangeUserTagsFromGeneric < ActiveRecord::Migration
  def self.up
    # convert generics to tag::user, unfortunately we have to do update ignore because the tagging combination might already exists in the tag::user form
    execute "UPDATE IGNORE taggings set taggings.tag_kind = 1 where taggings.tag_kind = 0 and taggings.taggable_type = 'User'"
    
    # delete the generic tags now
    execute "DELETE from taggings where taggings.tag_kind = 0 AND taggings.taggable_type = 'User'"
  end

  def self.down
  end
end
