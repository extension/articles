class AddMoreMetaToUpdateTime < ActiveRecord::Migration
  def self.up
    add_column(:update_times, :created_at, :datetime)
    add_column(:update_times, :updated_at, :datetime)
    add_column(:update_times, :additionaldata, :text)
  end

  def self.down
  end
end
