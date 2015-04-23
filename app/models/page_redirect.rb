# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PageRedirect < ActiveRecord::Base

  belongs_to :page
  attr_accessible :page, :page_id, :redirect_page_id, :reason

end
