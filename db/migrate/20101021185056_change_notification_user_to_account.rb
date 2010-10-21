class ChangeNotificationUserToAccount < ActiveRecord::Migration
  def self.up
    rename_column(:notifications, :user_id, :account_id)
  end

  def self.down
  end
end
