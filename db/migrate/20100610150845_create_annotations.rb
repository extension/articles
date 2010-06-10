class CreateAnnotations < ActiveRecord::Migration
  def self.up
    create_table :annotations do |t|
      t.string :href, :size => 1024
      t.string :url, :size => 1024
      t.datetime :added_at
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :annotations
  end
end
