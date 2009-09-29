class PrepareSqeForFollowup < ActiveRecord::Migration
  def self.up
    rename_column :submitted_question_events, :subject_user_id, :recipient_id
    add_column :submitted_question_events, :response_id, :integer, :null => true
    add_column :submitted_question_events, :public_user_id, :integer, :null => true
    add_column :submitted_question_events, :sent, :boolean, :null => false, :default => false
    # a little maintenance to responses table
    change_column :responses, :duration_since_last, :integer
  end

  def self.down
    rename_column :submitted_question_events, :recipient_id, :subject_user_id
    remove_column :submitted_question_events, :response_id
    remove_column :submitted_question_events, :public_user_id
    remove_column :submitted_question_events, :sent
    change_column :responses, :duration_since_last, :datetime
  end
end
