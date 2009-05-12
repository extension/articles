class RenameSubmitterEmail < ActiveRecord::Migration
  def self.up
    rename_column :submitted_questions, :external_submitter, :submitter_email
  end

  def self.down
    rename_column :submitted_questions, :submitter_email, :external_submitter
  end
end
