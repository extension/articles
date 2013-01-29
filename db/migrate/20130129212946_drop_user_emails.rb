class DropUserEmails < ActiveRecord::Migration
  def self.up
    drop_table "user_emails"
  end

  def self.down
  end
end
