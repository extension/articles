# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class Logo < ActiveRecord::Base
  
  # logotypes
  SPONSOR = 1
  COMMUNITY = 2
  INSTITUTION = 3
  
  scope :sponsorlogos, :conditions => {:logotype => SPONSOR} 
  
  has_attachment  :storage => :db_file, 
                  :content_type => :image,
                  :max_size => 1.megabytes,
                  :thumbnails => { :thumb => '100x100>' },
                  :processor => :rmagick

  validates_as_attachment
  
  
  #   def local_file=(path)
  #     raise 'Path doesn\'t exist...' unless File.exists?(path)
  #     self.content_type = File.mime_type?(path)
  #     self.filename     = File.basename(path)
  #     self.temp_path = path
  #   end

  def image_data(thumb_flag = false)
    if thumb_flag and the_thumb = thumbnails.first
      the_thumb.current_data
    else
      current_data
    end
  end

end
