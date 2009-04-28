# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class UpdateTime < ActiveRecord::Base
  belongs_to :datasource, :polymorphic => true
  
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def find_or_create(datasource,datatype)
      find_object = self.find(:first, :conditions => {:datasource_type => datasource.class.name,:datasource_id => datasource.id, :datatype => datatype})
      if(find_object.nil?)
        find_object = create(:datasource => datasource, :datatype => datatype)
      end
      return find_object
    end
    
  end
end