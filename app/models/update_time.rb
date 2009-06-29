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
      # allow association at the class level
      if(datasource.is_a?(Class))
        datasource_type = datasource.name
        findconditions = {:datasource_type => datasource_type,:datasource_id => 0, :datatype => datatype}
        createoptions = {:datasource_type => datasource_type, :datasource_id => 0, :datatype => datatype}
      else
        datasource_type = datasource.class.name
        findconditions = {:datasource_type => datasource_type,:datasource_id => datasource.id, :datatype => datatype}
        createoptions = {:datasource => datasource, :datatype => datatype}
      end
        
      find_object = self.find(:first, :conditions => findconditions)
      if(find_object.nil?)
        find_object = create(createoptions)
      end
      return find_object
    end
    
  end
end