#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'development'

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


#if anyone changes the schema of submitted_question_events from 9/30/09 with regards to these fields, this too must change and the hash fetch_hash statement below
def makenew(sqeid, sqid, initid, recipid, cr_at,  ev_state, pevid, dsl, precipid, pinitid, phan_evid, dshl, phan_evst, phan_recip, phan_initid )
  s = SubmittedQuestionEvent.new
  s.id=sqeid; s.submitted_question_id=sqid; s.initiated_by_id=initid; s.recipient_id=recipid; s.created_at=cr_at;
  s.event_state=ev_state;
  s.previous_event_id=pevid; s.duration_since_last=dsl;
  s.previous_recipient_id=precipid; s.previous_initiator_id=pinitid; s.previous_handling_event_id=phan_evid;
  s.duration_since_last_handling_event=dshl; s.previous_handling_event_state=phan_evst; s.previous_handling_recipient_id=phan_recip;
  s.previous_handling_initiator_id=phan_initid;
  s
end

def runsql(connection, sql)
# execute the sql
 
 begin
   result = connection.execute(sql)
 rescue => err
   ActiveRecord::Base::logger.error "ERROR: Exception raised during submitted_question_events data retrieval: #{err}"
   return false
 end
end


def update_from_submitted_question_events(connection)
  
  ActiveRecord::Base::logger.info "##################### Starting submitted_question_events data retrieval..."
  
  #General Purpose for this script: for each submitted question, find the question events table, and loop through it putting proper information
  # back into it for time between events
  previous_event_id=nil; duration_since_last=nil; previous_recipient_id=nil; previous_initiator_id=nil; 
  previous_handling_event_id=nil; duration_since_last_handling_event=nil; previous_handling_event_state=nil;
  previous_handling_recipient_id=nil; previous_handling_initiator_id=nil
  
  sqs = [] 
  sqsql = "Select id from submitted_questions"
  result = runsql(connection, sqsql)
  while sqh=result.fetch_hash do
    sqs << sqh['id']
  end
  sqs.each do |sqid|
    puts "sqid= " + sqid.to_s
    sqevents = []
    ## If this is changed, the fetch_hash below and make_new above must similarly change
    sql = "SELECT id as id, submitted_question_id submitted_question_id, initiated_by_id initiated_by_id, recipient_id  recipient_id, " + 
         " created_at created_at, event_state event_state, previous_event_id  previous_event_id, duration_since_last duration_since_last, " +
         "  previous_recipient_id previous_recipient_id, previous_initiator_id previous_initiator_id, previous_handling_event_id  previous_handling_event_id, " +
         " duration_since_last_handling_event  duration_since_last_handling_event, previous_handling_event_state  previous_handling_event_state, " +
         "   previous_handling_recipient_id  previous_handling_recipient_id, previous_handling_initiator_id  previous_handling_initiator_id " +
          "  from submitted_question_events where submitted_question_id=#{sqid}"
    result = runsql(connection, sql)
   
    
    #if anyone changes the schema with regard to these fields, and changes this, the select statement above would need to be changed, and also 'makenew' above
    while sqef=result.fetch_hash do
      sqevents << makenew(sqef['id'],sqef['submitted_question_id'],sqef['initiated_by_id'],sqef['recipient_id'],sqef['created_at'],sqef['event_state'],
           sqef['previous_event_id'],sqef['duration_since_last'],sqef['previous_recipient_id'],sqef['previous_initiator_id'],sqef['previous_handling_event_id'],
           sqef['duration_since_last_handling_event'],sqef['previous_handling_event_state'],sqef['previous_handling_recipient_id'],sqef['previous_handling_initiator_id'])
    end
    
    n = sqevents.size; i = 1
    puts "events size for sqid= " + sqid.to_s + " is: " + n.to_s
    
    while i < n do
      previous_event_id = sqevents[i-1].id
      duration_since_last = sqevents[i].created_at - sqevents[i - 1].created_at
      previous_recipient_id = sqevents[i - 1].recipient_id
      previous_initiator_id = sqevents[i - 1].initiated_by_id
      # cycle backwards to find the previous handling event
      j = i - 1; k = nil
      while j >= 0 do
        if sqevents[j].event_state == SubmittedQuestionEvent::ASSIGNED_TO or sqevents[j].event_state==SubmittedQuestionEvent::RESOLVED  or
             sqevents[j].event_state==SubmittedQuestionEvent::REJECTED or sqevents[j].event_state=SubmittedQuestionEvent::NO_ANSWER
          k = j
          break
        end
        j = j - 1
      end
      if k
        previous_handling_event_id = sqevents[k].id
        duration_since_last_handling_event = sqevents[i].created_at - sqevents[k].created_at
        previous_handling_event_state = sqevents[k].event_state
        previous_handling_recipient_id= sqevents[k].recipient_id
        previous_handling_initiator_id = sqevents[k].initiated_by_id
      end
      puts "updating sqe id= " + sqevents[i].id.to_s
      # form sql
      sql = " UPDATE submitted_question_events SET previous_event_id=#{previous_event_id}, "
      sql += " duration_since_last=#{duration_since_last}, "
      sql += (previous_recipient_id) ? "  previous_recipient_id=#{previous_recipient_id}," : ""
      sql +=    " previous_initiator_id=#{previous_initiator_id}"
      if k
        sql += ", "
        sql += " previous_handling_event_id=#{previous_handling_event_id},"
        sql += "duration_since_last_handling_event = #{duration_since_last_handling_event}, "
        sql += " previous_handling_event_state= #{previous_handling_event_state},"
        sql += "previous_handling_recipient_id= #{previous_handling_recipient_id}," 
        sql += "previous_handling_initiator_id= #{previous_handling_initiator_id}"
      end
      sql += " where submitted_question_events.id=#{sqevents[i].id}"
      
      res = runsql(connection, sql)
    
      i = i + 1
    end
  end  

  ActiveRecord::Base::logger.info "Finished submitted_question_events data retrieval and copy to new fields."
  return true
end

#################################
# Main

#database connection 
mydatabase = SubmittedQuestionEvent.connection.instance_variable_get("@config")[:database]
# go!
result = update_from_submitted_question_events(SubmittedQuestionEvent.connection)

