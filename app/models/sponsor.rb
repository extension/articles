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
  SPONSORSHIP_TAG_LIST = ["titanium", "platinum", "gold", "silver", "bronze"]

  named_scope :prioritized, {:include => :logo, :order => 'position ASC'}
  named_scope :tagged_with_sponsor_tag, lambda {|tagname| 
    {:include => {:taggings => :tag}, :conditions => "tags.name = '#{tagname}' AND taggings.tag_kind = #{Tagging::SPONSORSHIP}"}
  }

  # returns a comma delimited of the tags - with the primary content tag name first in the list
  # used for community editing in the administrative interface for public communities
  def content_tag_names()
    tagarray = self.tags_by_ownerid_and_kind(User.systemuserid,Tagging::CONTENT)
    if(!tagarray.blank?)
      return tagarray.collect(&:name).join(Tag::JOINER)
    else
      return ''
    end
  end  
  
  # this will silently strip out content tags in use by other communities
  # it's up to the controller level to deal with the warnings on this
  def content_tag_names=(taglist)
    self.replace_tags(taglist,User.systemuserid,Tagging::CONTENT)
    return self.content_tag_names           
  end
  
	def sponsor_tag_name()
		tagarray = self.tags_by_ownerid_and_kind(User.systemuserid,Tagging::SPONSORSHIP)
    if(!tagarray.blank?)
      return tagarray.collect(&:name)
    else
      return ''
    end
	end
	
	def sponsor_tag_name=(tag)
		self.replace_tags(tag,User.systemuserid,Tagging::SPONSORSHIP)
		return self.sponsor_tag_name
	end
end