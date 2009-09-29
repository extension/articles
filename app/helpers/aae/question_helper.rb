# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module Aae::QuestionHelper
  
def stringify_submitted_question_event(sq_event)
  
  if sq_event.initiated_by_id == User.systemuserid
    initiated_by_full_name = "System"
  elsif sq_event.initiated_by
    initiated_by_full_name = sq_event.initiated_by.fullname
  end
  
  case sq_event.event_state
  when SubmittedQuestionEvent::ASSIGNED_TO 
    reassign_msg = "Assigned to <strong><a href='/aae/profile?id=#{sq_event.recipient.login}'>#{sq_event.recipient.fullname}</a></strong> by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
    reassign_msg = reassign_msg + " <span>Comments: #{sq_event.response}</span>" if sq_event.response
    return reassign_msg 
  when SubmittedQuestionEvent::RESOLVED 
    return "Resolved by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::NO_ANSWER
    return "No answer available was sent from <strong>#{initiated_by_full_name}</strong><span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::MARKED_SPAM
    return "Marked as spam by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::MARKED_NON_SPAM
    return "Marked as non-spam by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::REJECTED
    return "Question Rejected by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::REACTIVATE
    return "Question Reactivated by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::RECATEGORIZED
    return "Question Recategorized by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::WORKING_ON
    return "Question worked on by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::EDIT_QUESTION
    return "Question edited by public user <span> #{humane_date(sq_event.created_at)}</span>"
  else
    return "Submitted question #{sq_event.submitted_question.id.to_s} #{SubmittedQuestion.convert_state_to_text(sq_event.event_state)} #{((sq_event.recipient) ? sq_event.recipient.fullname : '')} by #{initiated_by_full_name} <span> #{humane_date(sq_event.created_at)}</span>"
  end
end

def get_work_time_remaining(submitted_question)
  return nil if !submitted_question or submitted_question.status_state != SubmittedQuestion::STATUS_SUBMITTED
  latest_claim = SubmittedQuestionEvent.work_in_progress(submitted_question.assignee.id, submitted_question.id).latest
  return 0 if latest_claim.length == 0
  elapsed_time = Time.now - latest_claim[0].created_at 
  # 7200 sec == 2 hours
  return 7200 - elapsed_time
end


end


