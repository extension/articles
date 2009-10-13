class XferContributingQuestionsIntoResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :contributing_question_id, :integer, :null => true
    
    execute "UPDATE responses AS r JOIN submitted_questions AS sq on sq.id = r.submitted_question_id SET r.contributing_question_id = sq.current_contributing_question"
  end

  def self.down
    remove_column :responses, :contributing_question_id
  end
end
