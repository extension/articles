#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

# default environment
@environment = 'production'

progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    else
      puts "Unrecognized option #{opt}"
      exit 0
    end
end
### END Program Options

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = @environment
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

submitted_question_list = SubmittedQuestion.find(:all)
puts "Starting loop through SubmittedQuestion list, question count: #{submitted_question_list.size}"
submitted_question_list.each do |submitted_question|
  submitted_question_events = submitted_question.submitted_question_events.all(:order => 'created_at ASC,id ASC')        
  # we need to have at least two events to make it worthwhile looping through these.
  if(submitted_question_events.length > 1)
    puts "Looping through events for Submitted Question ID ##{submitted_question.id}, event count: #{submitted_question_events.length}"
    
    # get the values for the first event for this submitted question
    update_attributes = Hash.new
    update_attributes[:previous_event_id] = submitted_question_events[0].id
    update_attributes[:previous_recipient_id] = submitted_question_events[0].recipient_id
    update_attributes[:previous_initiator_id] = submitted_question_events[0].initiated_by
    if(submitted_question_events[0].is_handling_event?)
      previous_handling_event_index = 0
      update_attributes[:previous_handling_event_id] = submitted_question_events[0].id
      update_attributes[:previous_handling_recipient_id] = submitted_question_events[0].recipient_id
      update_attributes[:previous_handling_initiator_id] = submitted_question_events[0].initiated_by
      update_attributes[:previous_handling_event_state] = submitted_question_events[0].event_state
    end
    current_sqe_index = 1
    until current_sqe_index == submitted_question_events.length
      update_attributes[:duration_since_last] = (submitted_question_events[current_sqe_index].created_at - submitted_question_events[current_sqe_index - 1].created_at).to_i
      if(!update_attributes[:previous_handling_event_id].nil?)
        last_handling_event_time = submitted_question_events[previous_handling_event_index].created_at
        update_attributes[:duration_since_last_handling_event] = (submitted_question_events[current_sqe_index].created_at - last_handling_event_time).to_i
      end
      submitted_question_events[current_sqe_index].update_attributes(update_attributes)
      # update hash values
      update_attributes[:previous_event_id] = submitted_question_events[current_sqe_index].id
      update_attributes[:previous_recipient_id] = submitted_question_events[current_sqe_index].recipient_id
      update_attributes[:previous_initiator_id] = submitted_question_events[current_sqe_index].initiated_by
      if(submitted_question_events[current_sqe_index].is_handling_event?)
        previous_handling_event_index = current_sqe_index
        update_attributes[:previous_handling_event_id] = submitted_question_events[current_sqe_index].id
        update_attributes[:previous_handling_recipient_id] = submitted_question_events[current_sqe_index].recipient_id
        update_attributes[:previous_handling_initiator_id] = submitted_question_events[current_sqe_index].initiated_by
        update_attributes[:previous_handling_event_state] = submitted_question_events[current_sqe_index].event_state
      end
      current_sqe_index += 1
    end # loop of submitted questions
  else
    puts "Not enough events for Submitted Question ID ##{submitted_question.id}, event count: #{submitted_question_events.length}"
  end
end

