class AddAaeGroup < ActiveRecord::Migration
  def self.up
    add_column('communities', 'aae_group_id', :integer)

    # please make sure that the darmok database account has access to the aae_database before migrating!
    aae_database = AppConfig.configtable['ask2_database']

    update_tables = "communities, tags, taggings, categories, #{aae_database}.groups"
    set_statement = "communities.aae_group_id = #{aae_database}.groups.id"
    where_tags = "taggings.taggable_id = communities.id AND taggings.taggable_type = 'Community' and taggings.tagging_kind = #{Tagging::CONTENT_PRIMARY}"
    where_categories = "tags.name = categories.name AND taggings.tag_id = tags.id"
    where_groups = "categories.id = #{aae_database}.groups.darmok_expertise_id"

    execute "UPDATE #{update_tables} SET #{set_statement} WHERE #{where_tags} AND #{where_categories} AND #{where_groups}"

  end

  def self.down
    remove_column('communitites', 'aae_group_id')
  end
end
