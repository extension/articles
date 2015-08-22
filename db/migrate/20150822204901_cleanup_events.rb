class CleanupEvents < ActiveRecord::Migration
  def up

    # delete the events
    execute "DELETE from pages where datatype = 'Event'"

    # remove old columns
    remove_column(:pages, :event_start)
    remove_column(:pages, :time_zone)
    remove_column(:pages, :event_location)
    remove_column(:pages, :event_duration)
    remove_column(:pages, :event_all_day)
    remove_column(:pages, :learn_id)

  end
end
