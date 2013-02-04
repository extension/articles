class CleanupActivity < ActiveRecord::Migration
  def self.up
    drop_table "activity_objects"
    remove_column('activities', 'activity_object_id')

    # drop AaE activity
    execute "DELETE FROM activities where activitytype = 3"
    # drop "information" activity
    execute "DELETE FROM activities where activitytype = 2"

    drop_table "activity_events"
  end

  def self.down
  end
end
