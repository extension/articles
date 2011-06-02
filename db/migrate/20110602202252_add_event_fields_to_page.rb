class AddEventFieldsToPage < ActiveRecord::Migration
  def self.up
    add_column(:pages, :event_all_day, :boolean)
    execute "UPDATE pages SET event_all_day = 1 WHERE datatype = 'Event' and event_duration IS NOT NULL and event_duration >= 1"
  end

  def self.down
  end
end
