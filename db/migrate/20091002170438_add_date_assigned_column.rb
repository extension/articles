class AddDateAssignedColumn < ActiveRecord::Migration
  def self.up
     # add column to sq for date-assigned
     add_column :submitted_questions, :last_assign_date, :datetime

   end

   def self.down
     remove_column :submitted_questions, :last_assign_date
   end
end
