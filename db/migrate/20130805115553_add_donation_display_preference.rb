class AddDonationDisplayPreference < ActiveRecord::Migration
  def self.up
    add_column :publishing_communities, :show_donation, :boolean, :default => true
  end

  def self.down
    remove_column :publishing_communities, :show_donation
  end
end
