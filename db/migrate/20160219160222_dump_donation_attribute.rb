class DumpDonationAttribute < ActiveRecord::Migration
  def change
    remove_column(:publishing_communities, :show_donation)
  end
end
