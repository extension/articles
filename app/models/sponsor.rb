# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Sponsor < ActiveRecord::Base
  belongs_to :logo
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings

  acts_as_list

  SPONSORSHIP_LEVELS = ["titanium", "platinum", "gold", "silver", "bronze"]

  scope :prioritized, {:include => :logo, :order => 'position ASC'}

  scope :tagged_with, lambda{|tagliststring|
    tag_list = Tag.castlist_to_array(tagliststring)
    in_string = tag_list.map{|t| "'#{t}'"}.join(',')
    joins(:tags).where("tags.name IN (#{in_string})").group("#{self.table_name}.id").having("COUNT(#{self.table_name}.id) = #{tag_list.size}")
  }

  scope :tagged_with_any, lambda { |tagliststring|
    tag_list = Tag.castlist_to_array(tagliststring)
    in_string = tag_list.map{|t| "'#{t}'"}.join(',')
    joins(:tags).where("tags.name IN (#{in_string})").group("#{self.table_name}.id")
  }


  # returns a comma delimited of the tags - with the primary content tag name first in the list
  # used for community editing in the administrative interface for public communities
  def tag_names
    tags.collect(&:name).join(Tag::JOINER)
  end

  # this will silently strip out content tags in use by other communities
  # it's up to the controller level to deal with the warnings on this
  def tag_names=(taglist)
    self.replacetags_fromlist(taglist)
    self.tag_names
  end

  def replacetags_fromlist(taglist)
    replacelist = Tag.castlist_to_array(taglist)
    newtags = []
    replacelist.each do |tagname|
      if(tag = Tag.where(name: tagname).first)
        newtags << tag
      else
        newtags << Tag.create(name: tagname)
      end
    end
    self.tags = newtags
  end

end
