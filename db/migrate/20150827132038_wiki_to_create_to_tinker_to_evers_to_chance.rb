class WikiToCreateToTinkerToEversToChance < ActiveRecord::Migration
  def change
    add_column(:hosted_images, :create_fid, :integer)
    execute("UPDATE hosted_images SET create_fid = source_id where source = 'create'")
  end
end
