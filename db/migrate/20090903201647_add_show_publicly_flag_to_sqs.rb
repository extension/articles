class AddShowPubliclyFlagToSqs < ActiveRecord::Migration
  def self.up
    add_column :submitted_questions, :show_publicly, :boolean, :default => true
  end

  def self.down
    remove_column :submitted_questions, :show_publicly
  end
end
