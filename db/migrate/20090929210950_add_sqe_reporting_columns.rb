class AddSqeReportingColumns < ActiveRecord::Migration
  def self.up
    # id of last event
    add_column :submitted_question_events, :previous_event_id, :integer, :null => true
    # time in seconds since last event
    add_column :submitted_question_events, :duration_since_last, :integer, :null => true
    # the recipient of the last event
    add_column :submitted_question_events, :previous_recipient_id, :integer, :null => true
    # the initiator of the last event
    add_column :submitted_question_events, :previous_initiator_id, :integer, :null => true

    # "handling events" are events that meant that the question was "handled" - as of this migration
    # that would be "resolved" or "assigned" (reassigned)
    
    # id of last handling event
    add_column :submitted_question_events, :previous_handling_event_id, :integer, :null => true
    # time in seconds since last event
    add_column :submitted_question_events, :duration_since_last_handling_event, :integer, :null => true
    # state value of last event - see the event_state codes
    add_column :submitted_question_events, :previous_handling_event_state, :integer, :null => true
    # the recipient of the last handling event
    add_column :submitted_question_events, :previous_handling_recipient_id, :integer, :null => true
    # the initiator of the last handling event
    add_column :submitted_question_events, :previous_handling_initiator_id, :integer, :null => true
  end

  def self.down
    # really not much of a point in going back, even it's good practice
  end
end
