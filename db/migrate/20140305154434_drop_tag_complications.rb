class DropTagComplications < ActiveRecord::Migration
  def change
    remove_index(:taggings,  :name => "taggingindex")
    remove_index(:taggings,  :name => "index_taggings_on_taggable_id_and_taggable_type_and_tagging_kind")
    
    remove_column :pages, :cached_content_tags
    remove_column :taggings, :tagging_kind
    remove_column :taggings, :owner_id
    remove_column :taggings, :weight
    remove_column :taggings, :old_taggable_type
    remove_column :taggings, :old_taggable_id

    add_index "taggings", ["taggable_id", "taggable_type", "tag_id"], :name => "taggingindex", :unique => true

  end
end
