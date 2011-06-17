class SearchQuestionModifications < ActiveRecord::Migration
  def self.up
    rename_column(:responses, :contributing_question_id, :contributing_content_id)
    add_column(:responses, :contributing_content_type, :string)
    
    add_index(:responses, ['contributing_content_id','contributing_content_type'], :name => 'contributing_content_ndx')
    
    execute("UPDATE responses,search_questions SET responses.contributing_content_id = search_questions.foreignid, responses.contributing_content_type = 'SubmittedQuestion' where search_questions.entrytype = 2 and responses.contributing_content_id = search_questions.id")
    
    execute("UPDATE responses,search_questions,pages SET responses.contributing_content_id = pages.id, responses.contributing_content_type = 'Page' where search_questions.entrytype = 1 and responses.contributing_content_id = search_questions.id and pages.migrated_id = search_questions.foreignid and pages.datatype = 'Faq'")
    
    rename_column(:submitted_questions, :current_contributing_question, :contributing_content_id)
    add_column(:submitted_questions, :contributing_content_type, :string)
    
    add_index(:submitted_questions, ['contributing_content_id','contributing_content_type'], :name => 'contributing_content_ndx')
    
    execute("UPDATE submitted_questions,search_questions SET submitted_questions.contributing_content_id = search_questions.foreignid, submitted_questions.contributing_content_type = 'SubmittedQuestion' where search_questions.entrytype = 2 and submitted_questions.contributing_content_id = search_questions.id")
    
    execute("UPDATE submitted_questions,search_questions,pages SET submitted_questions.contributing_content_id = pages.id, submitted_questions.contributing_content_type = 'Page' where search_questions.entrytype = 1 and submitted_questions.contributing_content_id = search_questions.id and pages.migrated_id = search_questions.foreignid and pages.datatype = 'Faq'")
    
    rename_column(:submitted_question_events, :contributing_question, :contributing_content_id)
    add_column(:submitted_question_events, :contributing_content_type, :string)
    
    add_index(:submitted_question_events, ['contributing_content_id','contributing_content_type'], :name => 'contributing_content_ndx')
    
    
    execute("UPDATE submitted_question_events,search_questions SET submitted_question_events.contributing_content_id = search_questions.foreignid, submitted_question_events.contributing_content_type = 'SubmittedQuestion' where search_questions.entrytype = 2 and submitted_question_events.contributing_content_id = search_questions.id")
    
    execute("UPDATE submitted_question_events,search_questions,pages SET submitted_question_events.contributing_content_id = pages.id, submitted_question_events.contributing_content_type = 'Page' where search_questions.entrytype = 1 and submitted_question_events.contributing_content_id = search_questions.id and pages.migrated_id = search_questions.foreignid and pages.datatype = 'Faq'")
    
    execute 'ALTER TABLE `submitted_questions` ADD FULLTEXT `question_response_full_index` (`asked_question` ,`current_response`)'    
    execute 'ALTER TABLE `pages` ADD FULLTEXT `title_content_full_index` (`title` ,`content`)'    

    
  end

  def self.down
  end
end
