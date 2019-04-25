class AddMigratedDomainToPublishingCommunities < ActiveRecord::Migration
  def change
    add_column :publishing_communities, :migrated_domain, :string, :null => true
  end
end
