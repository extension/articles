# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'hpricot'

class SubmittedQuestionEvent < ActiveRecord::Base
  extend ConditionExtensions
  belongs_to :submitted_question
  belongs_to :initiated_by, :class_name => "User", :foreign_key => "initiated_by_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :previous_recipient, :class_name => "User", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "User", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "User", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "User", :foreign_key => "previous_handling_initiator_id"
  belongs_to :contributing_content, :polymorphic => true
  
  before_create :clean_response_and_additionaldata
  
  RESERVE_WINDOW = "date_sub(NOW(), interval 2 hour)"
    
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
  COMMENT = 14
  
  
  #scopes for sq events
  named_scope :work_in_progress, lambda { |user_id, sq_id| {:conditions => {:event_state => WORKING_ON, :initiated_by_id => user_id, :submitted_question_id => sq_id}}}
  named_scope :latest, {:order => "created_at desc", :limit => 1}
  named_scope :latest_handling, {:conditions => "event_state IN (#{ASSIGNED_TO},#{RESOLVED},#{REJECTED},#{NO_ANSWER})",:order => "created_at desc", :limit => 1}
  named_scope :handling_events, :conditions => "event_state IN (#{ASSIGNED_TO},#{RESOLVED},#{REJECTED},#{NO_ANSWER})"
  named_scope :response_events, :conditions => "event_state = #{RESOLVED}"

  # get all the questions with a 'I'm working on this' status (make sure the current question assignee is the one who claimed the question to work on it)
  named_scope :reserved_questions, {:select => "DISTINCT(submitted_question_events.submitted_question_id) AS id", :joins => :submitted_question, :conditions => "submitted_questions.user_id = submitted_question_events.initiated_by_id AND submitted_question_events.event_state = #{WORKING_ON} AND submitted_question_events.created_at > #{RESERVE_WINDOW}"}
  
  named_scope :submitted_question_filtered, lambda {|options| SubmittedQuestion.filterconditions(options.merge({:is_subfilter => true})).merge({:joins => :submitted_question})}  
  named_scope :submitted_question_not_rejected, :joins => :submitted_question, :conditions => ["submitted_questions.status_state != #{SubmittedQuestion::STATUS_REJECTED}"]   
  
  def is_handling_event?
    return ((self.event_state == ASSIGNED_TO) or (self.event_state == RESOLVED) or (self.event_state==REJECTED) or (self.event_state==NO_ANSWER))
  end
  
  
  def self.log_event(create_attributes = {})
    time_of_this_event = Time.now.utc
    submitted_question = create_attributes[:submitted_question]
    if create_attributes[:event_state] == ASSIGNED_TO
       submitted_question.update_attribute(:last_assigned_at, time_of_this_event)
    end

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
  
  def clean_response_and_additionaldata
    if self.response and self.response.strip != ''
      self.response = Hpricot(self.response).to_html 
    end
    
    if self.additionaldata and self.additionaldata.strip != ''
      self.additionaldata = Hpricot(self.additionaldata).to_html 
    end
  end
  
    
  def self.log_assignment(question, recipient, initiated_by, assignment_comment)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :recipient => recipient,
      :event_state => ASSIGNED_TO,
      :response => assignment_comment})
  end
  
  def self.log_comment(question, recipient, initiated_by, comment)
    sanitized_comment = Hpricot(comment.sanitize).to_html
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :recipient => recipient,
      :event_state => COMMENT,
      :response => sanitized_comment})
  end
  
  def self.log_reactivate(question, initiated_by)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => REACTIVATE})
  end
  
  def self.log_resolution(question)
    question.contributing_content ? contributing_content = question.contributing_content : contributing_content = nil
    
    return self.log_event({:submitted_question => question,
      :initiated_by => question.resolved_by,
      :event_state => RESOLVED,
      :response => question.current_response,
      :contributing_content => contributing_content})
  end
  
  def self.log_reopen(question, recipient, initiated_by, assignment_comment)
    question.update_attribute(:last_opened_at, Time.now)
    
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :recipient => recipient,
      :event_state => REOPEN,
      :response => assignment_comment})
  end
  
  def self.log_public_response(question, submitter_id)
    return self.log_event({:submitted_question => question,
      :initiated_by => User.systemuser,
      :event_state => PUBLIC_RESPONSE,
      :submitter_id => submitter_id})
  end
  
  def self.log_close(question, initiated_by, close_msg)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => CLOSED,
      :response => close_msg})
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
  
  def self.log_recategorize(question, initiated_by, category_string, previous_category_string)
    return self.log_event({:submitted_question => question,
      :initiated_by => initiated_by,
      :event_state => RECATEGORIZED,
      :category => category_string,
      :previous_category => previous_category_string})
  end
  
  def self.log_working_on(question, initiated_by)
    return self.log_event({:submitted_question => question,
       :initiated_by => initiated_by,
       :event_state => WORKING_ON})
  end
  
  def self.convert_state_to_text(state_number)
    case state_number
    when ASSIGNED_TO
      'assigned to'
    when RESOLVED
      'resolved by'
    when MARKED_SPAM
      'marked as spam'
    when MARKED_NON_SPAM
      'marked as non-spam'
    when REACTIVATE
      're-activated by'
    when REJECTED
      'rejected by'
    when NO_ANSWER
      'no answer given'
    when RECATEGORIZED
      're-categorized by'
    when WORKING_ON
      'worked on by'
    when EDIT_QUESTION
      'edited question'
    when PUBLIC_RESPONSE
      'public response'
    when REOPEN
      'reopened'
    when CLOSED
      'closed'
    when COMMENT
      'commented'
    else
      return nil
    end
  end
   
end
