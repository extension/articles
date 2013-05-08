class ModifyAnnotationEvents < ActiveRecord::Migration
  def self.up
    rename_column(:annotation_events, 'user_id', 'person_id')
    remove_column(:annotation_events, :login)

  end

  def self.down
  end
end
