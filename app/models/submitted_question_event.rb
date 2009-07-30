# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class SubmittedQuestionEvent < ActiveRecord::Base
  belongs_to :submitted_question
  belongs_to :initiated_by, :class_name => "User", :foreign_key => "initiated_by"
  belongs_to :subject_user, :class_name => "User", :foreign_key => "subject_user"
  
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
  
  ASSIGNED_TO = 1
  RESOLVED = 2
  MARKED_SPAM = 3
  MARKED_NON_SPAM = 4
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  RECATEGORIZED = 8
  WORKING_ON = 9
  
  #scopes for sq events
  named_scope :work_in_progress, lambda { |user_id, sq_id| {:conditions => {:event_state => WORKING_ON, :initiated_by => user_id, :submitted_question_id => sq_id}}}
  named_scope :latest, {:order => "created_at desc", :limit => 1}
  # get all the questions with a 'I'm working on this' status (make sure the current question assignee is the one who claimed the question to work on it)
  named_scope :reserved_questions, {:select => "DISTINCT(submitted_question_events.submitted_question_id) AS id", :joins => :submitted_question, :conditions => "submitted_questions.user_id = submitted_question_events.initiated_by AND submitted_question_events.event_state = #{WORKING_ON} AND submitted_question_events.created_at > #{RESERVE_WINDOW}"}
  
  
  def self.log_assignment(question, subject_user, initiated_by, assignment_comment)
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => initiated_by,
      :subject_user => subject_user,
      :event_type => ASSIGNED_TO_TEXT,
      :event_state => ASSIGNED_TO,
      :response => assignment_comment)
  end
  
  def self.log_reactivate(question, initiated_by)
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => initiated_by,
      :event_type => REACTIVATE_TEXT,
      :event_state => REACTIVATE)
  end
  
  def self.log_resolution(question)
    question.current_contributing_question ? contributing_question = question.current_contributing_question : contributing_question = nil
    
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => question.resolved_by,
      :event_type => RESOLVED_TEXT,
      :event_state => RESOLVED,
      :response => question.current_response,
      :contributing_question => contributing_question)
  end
  
  def self.log_no_answer(question)
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => question.resolved_by,
      :event_type => NO_ANSWER_TEXT,
      :event_state => NO_ANSWER,
      :response => question.current_response)
  end
  
  def self.log_rejection(question)
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => question.resolved_by,
      :event_type => REJECTED_TEXT,
      :event_state => REJECTED,
      :response => question.current_response)
  end
  
  def self.log_spam(question, initiated_by)
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => initiated_by,
      :event_type => MARKED_SPAM_TEXT,
      :event_state => MARKED_SPAM)
  end
  
  def self.log_non_spam(question, initiated_by)
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => initiated_by,
      :event_type => MARKED_NON_SPAM_TEXT,
      :event_state => MARKED_NON_SPAM)
  end
  
  def self.log_recategorize(question, initiated_by, category_string)
    SubmittedQuestionEvent.create(
      :submitted_question => question,
      :initiated_by => initiated_by,
      :event_type => RECATEGORIZED_TEXT,
      :event_state => RECATEGORIZED,
      :category => category_string
    )
  end
  
  def self.log_working_on(question, initiated_by)
    SubmittedQuestionEvent.create(
       :submitted_question => question,
       :initiated_by => initiated_by,
       :event_type => WORKING_ON_TEXT,
       :event_state => WORKING_ON
    )
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
