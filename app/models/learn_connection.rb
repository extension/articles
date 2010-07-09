# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LearnConnection < ActiveRecord::Base
  belongs_to :learn_session
  belongs_to :user  
  
  CREATOR = 1
  PRESENTER = 2
  INTERESTED = 3
  ATTENDED = 4
end