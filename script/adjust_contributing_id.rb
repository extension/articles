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



def update_from_submitted_question_events(connection)
  
  ActiveRecord::Base::logger.info "##################### Starting fixing legacy submitted questions that used a contributing_question_id directly instead of a foreignid referenced through the id of search_questions...."
  
  #General Purpose for this script: for each submitted question resolved before 8/12/2010, the first
   # place to look for the search_questions id is to find the foreign id equal to the old current_contributing_question field.
   #Then put the resulting search_questions id in the current_contributing_question field of the submitted_question and appropriate response contributing_question_ids. In rare instances, it
   # may be that we have to search on the fulltitle field of search_questions to find the proper search_question if the foreign id cannot be found.
 
   sqlist = SubmittedQuestion.find(:all, :conditions => "resolved_at < '2009-08-12' and current_contributing_question IS NOT NULL",:order => " submitted_questions.id")
  
  
   sqlist.each do |sq|
  
      searched_question = SearchQuestion.find_by_foreignid_and_entrytype(sq.current_contributing_question, SearchQuestion::FAQ)   
      puts "sqid= " + sq.id.to_s
      if searched_question
        puts "updating submitted_questions #{sq.id} with id of searched_question= #{searched_question.id}, old contributing_question= #{sq.current_contributing_question}"
       
       sq.update_attribute(:current_contributing_question, searched_question.id)
        #now find the responses and also change them
        sq.responses.each do |response|
          puts "updating response id=#{response.id} contributing_question_id from #{response.contributing_question_id} to #{searched_question.id}"
          response.update_attribute(:contributing_question_id, searched_question.id)
        end
        
      else
        ## in this case, the number in the current_contributing_question field is not found as a foreignid anywhere
        puts "the current_contributing_number #{sq.current_contributing_question} is not found as a foreign id in the search questions table"
        puts "attempting to match text on asked_question"
        searched_text = SearchQuestion.find_by_fulltitle_and_entrytype(sq.asked_question, SearchQuestion::FAQ)
        if searched_text
          puts "think we found #{sq.current_contributing_question}"
          sq.update_attribute(:current_contributing_question, searched_text.id)
            #now find the responses and also change them
            sq.responses.each do |response|
              puts "updating response id=#{response.id} contributing_question_id from #{response.contributing_question_id} to #{searched_question.id}"
              response.update_attribute(:contributing_question_id, searched_question.id)
            end
          
        end
      end
        
     
   end
 
  
  
  ActiveRecord::Base::logger.info "####Finished fixing legacy submitted questions that used a contributing_question_id directly instead of a foreignid referenced through the id of search_questions.######"
  return true
end

#################################
# Main

# go!
result = update_from_submitted_question_events(SubmittedQuestionEvent.connection)

