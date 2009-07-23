class RemoveSubmittedByFromSubmittedQuestions < ActiveRecord::Migration
  # very old legacy column that is said to have had origins in Ask a Peer
  def self.up
    remove_column :submitted_questions, :submitted_by
  end

  def self.down
  end
end
