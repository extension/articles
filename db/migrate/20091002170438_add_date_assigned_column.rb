class AddDateAssignedColumn < ActiveRecord::Migration
  def self.up
     # add column to sq for date-assigned
     add_column :submitted_questions, :last_assigned_at, :datetime

   end

   def self.down
     remove_column :submitted_questions, :last_assigned_at
   end
end
