class MergeSubmittedQuestionsAndExpertQuestions < ActiveRecord::Migration
  def self.up
    add_column :submitted_questions, :zip_code, :string, :null => true
    execute "Update submitted_questions as sq join expert_questions as eq on sq.question_fingerprint = eq.question_fingerprint SET sq.zip_code = eq.zip_code"
    drop_table :expert_questions
  end

  def self.down
    # nope, not happenin
  end
end
