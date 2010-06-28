# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LearnSession < ActiveRecord::Base
  has_many :learn_connections
  has_many :users, :through => :learn_connections, :select => "learn_connections.connectiontype as connectiontype, users.*"
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_modifier, :class_name => "User", :foreign_key => "last_modified_by"
  
end