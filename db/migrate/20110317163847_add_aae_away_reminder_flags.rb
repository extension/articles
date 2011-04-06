class AddAaeAwayReminderFlags < ActiveRecord::Migration
  def self.up
    add_column :accounts, :first_aae_away_reminder, :boolean, :default => false
    add_column :accounts, :second_aae_away_reminder, :boolean, :default => false
  end

  def self.down
  end
end
