class AddPublishingCommunity < ActiveRecord::Migration
  def self.up

    rename_column(:communities, 'show_in_public_list', 'publishing_community')

    create_table "publishing_communities", :force => true do |t|
      t.string   "name",                                                     :null => false
      t.string   "public_name"
      t.text     "public_description"
      t.boolean  "is_launched",                           :default => false
      t.integer  "public_topic_id"
      t.text     "cached_content_tag_data"
      t.integer  "logo_id",                               :default => 0
      t.string   "homage_name"
      t.integer  "homage_id"
      t.integer  "aae_group_id"
    end

    PublishingCommunity.reset_column_information
    
    select_columns = PublishingCommunity.column_names
    insert_clause = "#{PublishingCommunity.table_name} (#{select_columns.join(',')})"
    from_clause = "#{Community.table_name}"
    select_clause = "#{select_columns.join(',')}"
    where_clause = "WHERE entrytype != #{Community::INSTITUTION} and publishing_community = 1"
    transfer_query = "INSERT INTO #{insert_clause} SELECT #{select_clause} FROM #{from_clause} #{where_clause}"
    execute(transfer_query)

    execute "UPDATE taggings SET taggable_type = 'PublishingCommunity' where taggable_type = 'Community' and tagging_kind IN (3,4)"
  end

  def self.down
  end
end
