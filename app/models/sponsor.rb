# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Sponsor < ActiveRecord::Base
  belongs_to :logo
  acts_as_list
  has_content_tags
  SPONSORSHIP_LEVELS = ["titanium", "platinum", "gold", "silver", "bronze"]

  named_scope :prioritized, {:include => :logo, :order => 'position ASC'}

  # returns a comma delimited of the tags - with the primary content tag name first in the list
  # used for community editing in the administrative interface for public communities
  def content_tag_names()
    tagarray = self.tags_by_ownerid_and_kind(Person.systemuserid,Tagging::CONTENT)
    if(!tagarray.blank?)
      return tagarray.collect(&:name).join(Tag::JOINER)
    else
      return ''
    end
  end  
  
  # this will silently strip out content tags in use by other communities
  # it's up to the controller level to deal with the warnings on this
  def content_tag_names=(taglist)
    self.replace_tags(taglist,Person.systemuserid,Tagging::CONTENT)
    return self.content_tag_names           
  end
  
end