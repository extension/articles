class AddMoreTrackingFields < ActiveRecord::Migration
  def self.up
    add_column(:submitted_questions,:is_api,:boolean)
    add_column(:responses,:user_ip,:string)
    add_column(:responses,:user_agent,:string)
    add_column(:responses,:referrer,:string)    
  end

  def self.down
  end
end
