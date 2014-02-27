# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class PageUpdate < ActiveRecord::Base
  
  validates_presence_of :user_id, :page_id, :action
  
  belongs_to :user
  belongs_to :page
  
  scope :for, lambda { |page| { :conditions => {:page_id => page.id } }}
  scope :include_pages, :include => [:page]
  
  # TODO: Sugar like edit?, destroy? etc..
  
  # Get the humanized wording for this updates action.  I.e.
  # 'destroy' => 'deleted' etc...
  def humanize_action
    @humanized_action ||= case action
      when 'create' then 'created'
      when 'update' then 'updated'
      when 'destroy' then 'deleted'
      else 'edited'
    end
  end
end