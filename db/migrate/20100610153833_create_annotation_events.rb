class CreateAnnotationEvents < ActiveRecord::Migration
  def self.up
    create_table :annotation_events do |t|
      t.integer :id
      t.integer :user_id
      t.string :annotation_id, :size => 1024
      t.string :action
      t.string :ipaddr
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :annotation_events
  end
end
