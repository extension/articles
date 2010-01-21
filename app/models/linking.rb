# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


# join class for content <=> content_links

class Linking < ActiveRecord::Base
  belongs_to :content_link, :foreign_key => "content_link_id", :class_name => "ContentLink"  
  belongs_to :contentitem, :polymorphic => true
end