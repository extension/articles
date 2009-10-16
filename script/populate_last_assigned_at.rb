#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

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
  
  ActiveRecord::Base::logger.info "##################### Starting submitted_question_events ASSIGNED_TO time retrieval..."
  
  #General Purpose for this script: for each submitted question, find the question events table, find the last ASSIGNED_TO and put its time
  #back into the submitted question in last_assigned_at
   # Note: times below were done on a Snow Leopard laptop with Rails/MAMP
  
     
        #####        START OF SECTION A...RUN WITH LOGGING OFF...SET    config.level= :error    in production.rb
        #####  This is an Active Record way of doing this, more readable and maintainable for the one-time production run ####
        #####   This takes 3 minutes to run in production ,  ~ 5.5 hours to run in development (see section B below for an alternative for deveopment) (both prod and dev with logging off)#######
        #####    Reversing the comments here as section B is actually also faster in production. Uncomment if you prefer to run this, comment out section B below.  #####
        
#   sqlist = SubmittedQuestion.find(:all)
  
#   sqlist.each do |sq|
  
#     sqevent = Array.new
#     sqevent = sq.submitted_question_events.all( :conditions => "submitted_question_id=#{sq.id} and event_state=#{SubmittedQuestionEvent::ASSIGNED_TO}", :order => "created_at DESC")
     
#      puts "sqid= " + sq.id.to_s

#     if !sqevent.empty?
#       puts "updating sqid= " + sq.id.to_s
       
#       sq.update_attribute(:last_assigned_at, sqevent[0].created_at)
#     end
     
#   end
 
    #######                    END OF SECTION A                            ##########
  
    
    ####     START OF SECTION B...RUN WITH LOGGING OFF, set    config.log_level= :error    in your development.rb or production.rb #######
   #####  This section B here takes 1 hour currently (20000+ submitted questions) to run in development. 2 minutes to run in production. ######
   #####    To run in development, specify 'development' above    #####
#####  START OF SECTION B  ######
  sqs = [] 
  sqsql = "Select id from submitted_questions"
  result = runsql(connection, sqsql)
  while sqh=result.fetch_hash do
    sqs << sqh['id']
  end

  sqs.each do |sqid|
 
    sql = "SELECT created_at from submitted_question_events " + 
        " where submitted_question_id=#{sqid} and event_state=#{SubmittedQuestionEvent::ASSIGNED_TO} order by created_at DESC LIMIT 1"
    result = runsql(connection, sql)
    sqevents = []
 
    while sqef=result.fetch_hash do
      sqevents << sqef['created_at']    
      break
    end

    puts  " sqevents.size= " + sqevents.size.to_s
    if sqevents.size > 0
      puts "updating sq id= " + sqid.to_s
         # form sql
      sql = " UPDATE submitted_questions SET last_assigned_at='#{sqevents[0]}'"
      sql += " where submitted_questions.id=#{sqid}"
       
      res = runsql(connection, sql)
    end
  end
   ##############                End of  SECTION B  to be run for development            ############
  
  
  ActiveRecord::Base::logger.info "####Finished submitted_question_events ASSIGNED_TO time retrieval and copy submitted_question last_assigned_at.######"
  return true
end

#################################
# Main

# go!
result = update_from_submitted_question_events(SubmittedQuestionEvent.connection)

