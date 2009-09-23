class AddMailmanTimestamp < ActiveRecord::Migration
  def self.up
    add_column(:lists, :last_mailman_update, :datetime)
  end

  def self.down
  end
end
