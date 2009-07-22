# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module Ask::ExpertHelper
  
def stringify_submitted_question_event(sq_event)
  case sq_event.event_state
  when SubmittedQuestionEvent::ASSIGNED_TO 
    if sq_event.initiated_by == User.systemuser
      initiated_by_full_name = "System"
    else
      initiated_by_full_name = sq_event.initiated_by..fullname
    end

    reassign_msg = "Assigned to <strong><a href='/account/aaeprofile/#{sq_event.subject_user.login}'>#{sq_event.subject_user..fullname}</a></strong> by <strong>#{initiated_by_full_name}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
    reassign_msg = reassign_msg + " <span>Comments: #{sq_event.response}</span>" if sq_event.response
    return reassign_msg 
  when SubmittedQuestionEvent::RESOLVED 
    return "Resolved by <strong>#{sq_event.initiated_by..fullname}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::NO_ANSWER
    return "No answer available was sent from <strong>#{sq_event.initiated_by..fullname}</strong><span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::MARKED_SPAM
    return "Marked as spam by <strong>#{sq_event.initiated_by..fullname}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::MARKED_NON_SPAM
    return "Marked as non-spam by <strong>#{sq_event.initiated_by..fullname}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::REJECTED
    return "Question Rejected by <strong>#{sq_event.initiated_by..fullname}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::REACTIVATE
    return "Question Reactivated by <strong>#{sq_event.initiated_by..fullname}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::RECATEGORIZED
    return "Question Recategorized by <strong>#{sq_event.initiated_by..fullname}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  when SubmittedQuestionEvent::WORKING_ON
    return "Question worked on by <strong>#{sq_event.initiated_by..fullname}</strong> <span> #{humane_date(sq_event.created_at)}</span>"
  else
    return "Submitted question #{sq_event.submitted_question.id.to_s} #{SubmittedQuestion.convert_state_to_text(sq_event.event_state)} #{((sq_event.subject_user) ? sq_event.subject_user..fullname : '')} by #{sq_event.initiated_by..fullname} <span> #{humane_date(sq_event.created_at)}</span>"
  end
end

def getExperts(community)
  users = Array.new
  
  roles = community.role_assignments
  roles.each do |role|
    users << role.user
  end  
  
  users.uniq!
  
  users
end

def get_work_time_remaining(submitted_question)
  return nil if !submitted_question or submitted_question.status_state != SubmittedQuestion::STATUS_SUBMITTED
  latest_claim = SubmittedQuestionEvent.work_in_progress(submitted_question.assignee.id, submitted_question.id).latest
  return 0 if latest_claim.length == 0
  elapsed_time = Time.now - latest_claim[0].created_at 
  # 7200 sec == 2 hours
  return 7200 - elapsed_time
end

def outstandingQuestionsCount(submittedQuestions)
  questionsArray = Array.new
  questionsArray = submittedQuestions.find_all {|sq| sq.status_state == SubmittedQuestion::STATUS_SUBMITTED}
  return questionsArray.length
end

def formatDate(strDate)
  strDate = strDate.to_s
  dateArr = strDate.split(' ')
  newDate = dateArr[1] + " " + dateArr[2] + " " + dateArr[5]
  newDate  
end

# http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
def wrap_text(txt, col=120)
  txt.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
    "\\1\\3\n") 
end


end


