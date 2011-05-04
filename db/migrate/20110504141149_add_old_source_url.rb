class AddOldSourceUrl < ActiveRecord::Migration
  def self.up
    # for tracking old_source_url for a time - part of the drupal migration
    add_column(:pages, 'old_source_url', :text)
  end

  def self.down
  end
end
