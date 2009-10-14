# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'hpricot'

class Response < ActiveRecord::Base
  belongs_to :submitted_question
  belongs_to :resolver, :class_name => "User", :foreign_key => "user_id"
  belongs_to :public_responder, :class_name => "PublicUser", :foreign_key => "public_user_id"
  belongs_to :contributing_question, :class_name => "SearchQuestion", :foreign_key => "contributing_question_id"
  
  before_create :calculate_duration_since_last, :clean_response
  
  
  def calculate_duration_since_last
    parent_submitted_question_id = self.submitted_question_id
    last_response = Response.find(:first, :conditions => {:submitted_question_id => parent_submitted_question_id}, :order => "created_at DESC")
    if last_response
      self.duration_since_last = Time.now - last_response.created_at
    else
      self.duration_since_last = 0
    end
  end
  
  def clean_response
    self.response = Hpricot(self.response.sanitize).to_html 
  end
  
end