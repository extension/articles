class ReworkAssetsLogosSponsors < ActiveRecord::Migration
  def self.up
    rename_table(:assets, :logos)
    
    # sponsor model changes
    rename_column(:sponsors, :image_id, :logo_id)
    add_column(:sponsors, :name, :string)
    
  end

  def self.down
  end
end
