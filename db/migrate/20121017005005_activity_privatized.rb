class ActivityPrivatized < ActiveRecord::Migration
  def self.up
    execute "UPDATE activities set privacy = 100 where activitytype IN (2,3)"
  end

  def self.down
  end
end
