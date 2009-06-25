# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class Category < ActiveRecord::Base
  acts_as_tree :order => 'name'
  
  def self.root_categories
    Category.find(:all, :conditions => 'parent_id is null', :order => 'name')
  end
  
  
end