class AddLastOpenedAt < ActiveRecord::Migration
  # this column is for the last time an inquiry was made by the public on a question or the expert reopened it.
  # useful for determining if a question has sat unresolved for too long.
  def self.up
    add_column :submitted_questions, :last_opened_at, :datetime, :null => false
    
    # populate existing sq's with created_at for the last_opened_at b/c at this point,
    # the existing ones do not have any reopened actions performed on them, just a created_at
    execute "UPDATE submitted_questions SET last_opened_at = created_at"
  end

  def self.down
    remove_column :submitted_questions, :last_opened_at
  end
end
