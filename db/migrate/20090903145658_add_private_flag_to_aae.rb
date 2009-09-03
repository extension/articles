class AddPrivateFlagToAae < ActiveRecord::Migration
  def self.up
    add_column :submitted_questions, :private, :boolean, :default => false
  end

  def self.down
    remove_column :submitted_questions, :private
  end
end
