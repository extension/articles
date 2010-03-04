# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# The Tagging join model. This model is automatically generated and added to your app if you run the tagging generator included with has_many_polymorphs.

class Tagging < ActiveRecord::Base 
  # tag_kinds
  GENERIC = 0  # table defaults
  USER = 1
  SHARED = 2
  CONTENT = 3
  CONTENT_PRIMARY = 4  # for public communities, indicates the primary content tag for the community, if more than one

  # special class of 'all' for caching purposes
  ALL = 42  # the ultimate answer, of course

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :tag, :foreign_key => "tag_id", :class_name => "Tag"
  belongs_to :taggable, :polymorphic => true
  
  # If you also need to use <tt>acts_as_list</tt>, you will have to manage the tagging positions manually by creating decorated join records when you associate Tags with taggables.
  # acts_as_list :scope => :taggable
    
  # This callback makes sure that an orphaned <tt>Tag</tt> is deleted if it no longer tags anything.
  def before_destroy
    tag.destroy_without_callbacks if tag and tag.taggings.count == 1
  end    
end
