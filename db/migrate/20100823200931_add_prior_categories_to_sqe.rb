class AddPriorCategoriesToSqe < ActiveRecord::Migration
  def self.up
    add_column(:submitted_question_events, :previous_category, :string)
    execute "UPDATE submitted_question_events SET previous_category = 'unknown' where event_state = #{SubmittedQuestionEvent::RECATEGORIZED}"
    execute "UPDATE submitted_question_events SET category =  REPLACE(category,'/',':')"
  end

  def self.down
  end
end
