class MoveSqDataToResponses < ActiveRecord::Migration
  def self.up
    execute "INSERT INTO responses (user_id, public_user_id, submitted_question_id, response, duration_since_last, sent, created_at, updated_at) " + 
    "SELECT sq.resolved_by, NULL, sq.id, sq.current_response, 0, true, sq.created_at, sq.created_at FROM submitted_questions as sq " + 
    "WHERE sq.status_state = #{SubmittedQuestion::STATUS_RESOLVED} OR sq.status_state = #{SubmittedQuestion::STATUS_NO_ANSWER}"
  end

  def self.down
    # not happenin
  end
end
