# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AnnotationEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :annotation, :primary_key => :url
  
  before_save :set_ip_address, :set_user
  
  URL_ADDED = 'added'
  URL_DELETED = 'deleted'
  
  def set_ip_address
    if (defined? request) and request.remote_ip
      self.ipaddr = request.remote_ip
    else
      self.ipaddr = "127.0.0.1"
    end
  end
  
  def set_user
    if (defined? @currentuser) and ! @currentuser.nil?
      self.user = @currentuser
    else
      self.user = User.systemuser
    end
  end
  
  def self.log_event(annotation, action)
    event = AnnotationEvent.new(:annotation => annotation, :action => action)
    event.save
  end
end