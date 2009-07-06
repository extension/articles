class ChangeContributingFaqToQuestion < ActiveRecord::Migration
  def self.up
    rename_column :submitted_questions, :current_contributing_faq, :current_contributing_question
    rename_column :submitted_question_events, :contributing_faq, :contributing_question
  end

  def self.down
    rename_column :submitted_questions, :current_contributing_question, :current_contributing_faq
    rename_column :submitted_question_events, :contributing_question, :contributing_faq
  end
end
