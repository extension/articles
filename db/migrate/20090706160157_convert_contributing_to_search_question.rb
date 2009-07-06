class ConvertContributingToSearchQuestion < ActiveRecord::Migration
  # search_questions table is used to find possible answers to AaE questions by using a full text search on 
  # published faqs and now resolved AaE questions and draft faqs
  def self.up
    execute("Update submitted_questions as sq join search_questions as se_q on sq.current_contributing_faq = se_q.foreignid " +
            "SET sq.current_contributing_faq = se_q.id WHERE se_q.entrytype = #{SearchQuestion::FAQ}")
    execute("Update submitted_question_events as sqe join search_questions as se_q on sqe.contributing_faq = se_q.foreignid " +
            "SET sqe.contributing_faq = se_q.id WHERE se_q.entrytype = #{SearchQuestion::FAQ}")
            
  end

  def self.down
  end
end
