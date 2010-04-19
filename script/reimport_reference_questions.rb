#!/usr/bin/env ruby
require 'getoptlong'
### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--faqdb","-f", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@refreshall = false
@provided_date = nil
@faqdb = 'prod_dega'
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--refreshall'
      @refreshall = true
    when '--faqdb'
      @faqdb = arg
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

mydatabase = Faq.connection.instance_variable_get("@config")[:database]
sub_query = "SELECT #{@faqdb}.questions.id as question_id, #{@faqdb}.revisions.reference_string as reference_questions FROM #{@faqdb}.questions, #{@faqdb}.revisions"
sub_query += " WHERE #{@faqdb}.questions.published_revision = #{@faqdb}.revisions.id AND #{@faqdb}.revisions.reference_string IS NOT NULL"
update_query = "UPDATE #{mydatabase}.faqs, (#{sub_query}) as faq_query"
update_query += " SET #{mydatabase}.faqs.reference_questions = faq_query.reference_questions WHERE #{mydatabase}.faqs.id = faq_query.question_id"
# execute sql 
begin
  Faq.connection.execute(update_query)
rescue => err
  puts "ERROR: Exception raised during FAQ reference_questions retrieval: #{err}"
end    
