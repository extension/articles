class AddContentBucketForNoIndex < ActiveRecord::Migration
  def self.up
    ContentBucket.create(:name => 'noindex')
  end

  def self.down
  end
end
