class RenameSqeColumns < ActiveRecord::Migration
  def self.up
    rename_column(:submitted_question_events, :subject_user, :subject_user_id)
    rename_column(:submitted_question_events, :initiated_by, :initiated_by_id)

  end

  def self.down
  end
end
