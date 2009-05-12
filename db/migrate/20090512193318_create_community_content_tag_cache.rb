class CreateCommunityContentTagCache < ActiveRecord::Migration
  def self.up
    # since we ask for these over and over and over - let's put in a special serialized column with the cached content tags for the community
    # this really doesn't fit it with the tag cache mechanism - I'm not sure that the tag cache mechanism fits in with anything at this moment
    add_column(:communities, :cached_content_tag_data, :text)
  end

  def self.down
  end
end
