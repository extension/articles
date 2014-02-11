# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file


# join class for content <=> links

class Linking < ActiveRecord::Base
  belongs_to :link
  belongs_to :page
end