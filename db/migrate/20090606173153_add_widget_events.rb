class AddWidgetEvents < ActiveRecord::Migration
  def self.up
    create_table :widget_events do |t|
      t.integer :widget_id, :user_id, :null => false
      t.string :event, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :widget_events
  end
end
