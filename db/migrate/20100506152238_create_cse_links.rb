class CreateCseLinks < ActiveRecord::Migration
  def self.up
    create_table :cse_links do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :cse_links
  end
end
