class AddAdditionalDataToUsers < ActiveRecord::Migration
  def self.up
    remove_column(:users,:is_staff)
    add_column(:users, :additionaldata, :text)
  end

  def self.down
  end
end
