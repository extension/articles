class AddPrimaryTagToPublishingCommunities < ActiveRecord::Migration
  def change
    add_column :publishing_communities, :primary_tag_id, :integer

    # set them
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE publishing_communities,taggings
    SET publishing_communities.primary_tag_id = taggings.tag_id
    WHERE taggings.taggable_type = 'PublishingCommunity'
    AND taggings.taggable_id = publishing_communities.id
    AND taggings.tagging_kind = #{Tagging::CONTENT_PRIMARY}
    END_SQL
    execute query

    # delete them
    execute "DELETE from taggings where tagging_kind = #{Tagging::CONTENT_PRIMARY}"

  end
end
