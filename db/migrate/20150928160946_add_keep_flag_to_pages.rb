class AddKeepFlagToPages < ActiveRecord::Migration
  def change
    add_column(:pages, :keep_published, :boolean, :default => true)
  end
end
