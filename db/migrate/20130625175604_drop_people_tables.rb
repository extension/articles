class DropPeopleTables < ActiveRecord::Migration
  def self.up
    drop_table "accounts"
    drop_table "activities"
    drop_table "activity_applications"
    drop_table "api_key_events"
    drop_table "api_keys"
    drop_table "chat_accounts"
    drop_table "communities"
    drop_table "communityconnections"
    drop_table "directory_item_caches"
    drop_table "email_aliases"
    drop_table "google_accounts"
    drop_table "google_groups"
    drop_table "invitations"
    drop_table "lists"
    drop_table "notifications"
    drop_table "old_institutions"
    drop_table "open_id_associations"
    drop_table "open_id_nonces"
    drop_table "opie_approvals"
    drop_table "positions"
    drop_table "privacy_settings"
    drop_table "social_networks"
    drop_table "user_events"
    drop_table "user_tokens"

    # trash taggings
    execute "DELETE FROM taggings where taggable_type = 'Community'"
    execute "DELETE FROM taggings where taggable_type = 'Account'"

    # trash unused tags
    execute "DELETE from tags where id NOT IN (SELECT tag_id from taggings)"


  end
end
