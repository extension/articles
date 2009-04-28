# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class PendingOperation < ActiveRecord::Base
  ADDITION = 0
  REMOVAL = 1
  
  belongs_to :user
  belongs_to :list
end
