# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class SubmittedQuestionEvent < ActiveRecord::Base
  belongs_to :submitted_question
  belongs_to :initiated_by, :class_name => "User", :foreign_key => "initiated_by_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :previous_recipient, :class_name => "User", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "User", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "User", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "User", :foreign_key => "previous_handling_initiator_id"
  
  RESERVE_WINDOW = "date_sub(NOW(), interval 2 hour)"
  
  ASSIGNED_TO_TEXT = 'assigned to'
  RESOLVED_TEXT = 'resolved by'
  MARKED_SPAM_TEXT = 'marked as spam'
  MARKED_NON_SPAM_TEXT = 'marked as non-spam'
  REACTIVATE_TEXT = 're-activated by'
  REJECTED_TEXT = 'rejected by'
  NO_ANSWER_TEXT = 'no answer given'
  RECATEGORIZED_TEXT = 're-categorized by'
  WORKING_ON_TEXT = 'worked on by'
  EDITED_QUESTION_TEXT = 'edited question'
  PUBLIC_RESPONSE_TEXT = 'public response'
  REOPEN_TEXT = 'reopened'
  CLOSED_TEXT = 'closed'
  
  ASSIGNED_TO = 1
  RESOLVED = 2
  MARKED_SPAM = 3
  MARKED_NON_SPAM = 4
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  RECATEGORIZED = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  
  
  #scopes for sq events
  named_scope :work_in_progress, lambda { |user_id, sq_id| {:conditions => {:event_state => WORKING_ON, :initiated_by_id => user_id, :submitted_question_id => sq_id}}}
  named_scope :latest, {:order => "created_at desc", :limit => 1}
  named_scope :latest_handling, {:conditions => "event_state IN (#{ASSIGNED_TO},#{RESOLVED})",:order => "created_at desc", :limit => 1}
  # get all the questions with a 'I'm working on this' status (make sure the current question assignee is the one who claimed the question to work on it)
  named_scope :reserved_questions, {:select => "DISTINCT(submitted_question_events.submitted_question_id) AS id", :joins => :submitted_question, :conditions => "submitted_questions.user_id = submitted_question_events.initiated_by_id AND submitted_question_events.event_state = #{WORKING_ON} AND submitted_question_events.created_at > #{RESERVE_WINDOW}"}
  
  
  def is_handling_event?
    return ((self.event_state == ASSIGNED_TO) or (self.event_state == RESOLVED))
  end
  
  def self.log_event(create_attributes = {})
    time_of_this_event = Time.now.utc
    submitted_question = create_attributes[:submitted_question]

    # get last event
    if(last_events = submitted_question.submitted_question_events.latest and !last_events.empty?)
      last_event = last_events[0]
      create_attributes[:duration_since_last] = (time_of_this_event - last_event.created_at).to_i
      create_attributes[:previous_recipient_id] = last_event.recipient_id
      create_attributes[:previous_initiator_id] = last_event.initiated_by_id
      create_attributes[:previous_event_id] = last_event.id
      # if not a handling event, get the last handling event
      if(!last_event.is_handling_event?)
        if(last_handling_events = submitted_question.submitted_question_events.latest_handling and !last_handling_events.empty?)
          last_handling_event = last_handling_events[0]
          create_attributes[:previous_handling_event_id] = last_handling_event.id          
          create_attributes[:duration_since_last_handling_event] = (time_of_this_event - last_handling_event.created_at).to_i
          create_attributes[:previous_handling_event_state] = last_handling_event.event_state
          create_attributes[:previous_handling_recipient_id] = last_handling_event.recipient_id
          create_attributes[:previous_handling_initiator_id] = last_handling_event.initiated_by_id
        end
      else
        # last_event was a handling event - so use the last_event details to fill those values in
        create_attributes[:previous_handling_event_id] = last_event.id
        create_attributes[:duration_since_last_handling_event] = (time_of_this_event - last_event.created_at).to_i
        create_attributes[:previous_handling_event_state] = last_event.event_state
        create_attributes[:previous_handling_recipient_id] = last_event.recipient_id
        create_attributes[:previous_handling_initiator_id] = last_event.initiated_by_id
      end
    end

    return SubmittedQuestionEvent.create(create_attributes)    
  end
  
    
  def self.log_assignment(question, recipient, initiated_by, assignment_comment)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :recipient => recipient,
      :event_state => ASSIGNED_TO,
      :response => assignment_comment})
  end
  
  def self.log_reactivate(question, initiated_by)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => REACTIVATE})
  end
  
  def self.log_resolution(question)
    question.current_contributing_question ? contributing_question = question.current_contributing_question : contributing_question = nil
    
    return self.log_event({:submitted_question => question,
      :initiated_by => question.resolved_by,
      :event_state => RESOLVED,
      :response => question.current_response,
      :contributing_question => contributing_question})
  end
  
  def self.log_reopen(question, recipient, initiated_by, assignment_comment)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :recipient => recipient,
      :event_state => REOPEN,
      :response => assignment_comment})
  end
  
  def self.log_close(question, initiated_by)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => CLOSED})
  end
  
  def self.log_no_answer(question)
    return self.log_event({:submitted_question => question,
      :initiated_by => question.resolved_by,
      :event_state => NO_ANSWER,
      :response => question.current_response})
  end
  
  def self.log_rejection(question)
    return self.log_event({:submitted_question => question,
      :initiated_by => question.resolved_by,
      :event_state => REJECTED,
      :response => question.current_response})
  end
  
  def self.log_spam(question, initiated_by)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => MARKED_SPAM})
  end
  
  def self.log_non_spam(question, initiated_by)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => MARKED_NON_SPAM})
  end
  
  def self.log_recategorize(question, initiated_by, category_string)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => RECATEGORIZED,
      :category => category_string})
  end
  
  def self.log_working_on(question, initiated_by)
    return self.log_event({:submitted_question => question,
       :initiated_by => initiated_by,
       :event_state => WORKING_ON})
  end
  
  def self.convert_state_to_text(state_number)
    case state_number
    when 1
      return ASSIGNED_TO_TEXT
    when 2
      return RESOLVED_TEXT
    when 3
      return MARKED_SPAM_TEXT
    when 4
      return MARKED_NON_SPAM_TEXT
    when 5
      return REACTIVATE_TEXT
    when 6 
      return REJECTED_TEXT
    when 7 
      return NO_ANSWER_TEXT
    when 8
      return RECATEGORIZED_TEXT
    when 9
      return WORKING_ON_TEXT
    else
      return nil
    end
  end
  
end
