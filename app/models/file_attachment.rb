# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FileAttachment < ActiveRecord::Base
  
  belongs_to :responses
  belongs_to :submitted_questions
  has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" },
  :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  
  validates_attachment_presence :attachment
  validates_attachment_content_type :attachment, :content_type => ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png']
  validates_attachment_size :attachment, :less_than => 2.megabytes
  
  attr_accessible :attachment          
  
  before_create :randomize_attachment_file_name
  
  MAX_AAE_UPLOADS = 3
  
  def randomize_attachment_file_name
    return if self.attachment_file_name.nil?
    extension = File.extname(attachment_file_name).downcase
    self.attachment.instance_write(:file_name, "#{ActiveSupport::SecureRandom.hex(16)}#{extension}")
  end
  
end
