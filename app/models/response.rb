# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Response < ActiveRecord::Base
  belongs_to :submitted_question
  belongs_to :resolver, :class_name => "User", :foreign_key => "user_id"
  belongs_to :public_responder, :class_name => "PublicUser", :foreign_key => "public_user_id"
  

  
end