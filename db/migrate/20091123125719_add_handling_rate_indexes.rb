class AddHandlingRateIndexes < ActiveRecord::Migration
  def self.up
    # add index for submitted_questions.status_state - since we limit handling rates to !rejected questions
    add_index("submitted_questions","status_state")
    # the columns queried most often are created_at, event_state, and previous_handling_recipient_id
    add_index "submitted_question_events", ["created_at","event_state","previous_handling_recipient_id"], :name => "handling_idx"
  end

  def self.down
  end
end
