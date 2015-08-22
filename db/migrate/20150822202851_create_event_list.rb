class CreateEventList < ActiveRecord::Migration

  def change
    create_table "old_event_ids", :force => true do |t|
      t.integer   "event_id",:null => false
    end
    add_index "old_event_ids", ["event_id"], :name => "event_ndx", :unique => true

    # populate
    execute "INSERT INTO old_event_ids (event_id) SELECT id from pages where datatype = 'Event'"
  end

end
