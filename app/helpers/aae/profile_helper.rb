# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module Aae::ProfileHelper

  def get_expertise_subcategories(user_expertise, parent_category_id)
    return_string = ''
    
    user_expertise.select{|expertise_category| expertise_category.parent_id == parent_category_id}.each do |subcat| 
      return_string << "<li>#{subcat.full_name}</li>"
    end
    
    return return_string 
  end

end