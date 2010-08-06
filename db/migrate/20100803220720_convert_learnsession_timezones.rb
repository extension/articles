class ConvertLearnsessionTimezones < ActiveRecord::Migration
  def self.up
    rename_column(:learn_sessions, 'time_zone', 'old_time_zone')
    add_column(:learn_sessions, :time_zone, :string)
    # data conversion
    LearnSession.reset_column_information
    LearnSession.all.each do |ls|
      ls.update_attribute(:time_zone, ls.old_time_zone)
    end
    remove_column(:learn_sessions, 'old_time_zone')
  end

  def self.down
    # not going back
  end
end
