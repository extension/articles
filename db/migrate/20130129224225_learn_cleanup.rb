class LearnCleanup < ActiveRecord::Migration
  def self.up
    # trash taggings
    execute "DELETE FROM taggings where taggable_type = 'LearnSession'"
  end

  def self.down
  end
end
