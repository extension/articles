class HideFromAaeFlag < ActiveRecord::Migration
  def self.up
    add_column(:communities, :hide_from_aae, :boolean, :default => false)
  end

  def self.down
  end
end
