# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at https://github.com/extension/darmok/wiki/LICENSE

class SpecialPage < ActiveRecord::Base
  belongs_to :page
  
  after_create :set_page_flag
  
  def set_page_flag
    self.page.update_attribute(:is_special_page, true)
  end
  
end