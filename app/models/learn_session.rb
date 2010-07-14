# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LearnSession < ActiveRecord::Base
  
  before_save :calculate_end_time
  
  has_many :learn_connections
  has_many :users, :through => :learn_connections, :select => "learn_connections.connectiontype as connectiontype, users.*"
  has_many :presenters, :through => :learn_connections, :conditions => "learn_connections.connectiontype = '#{LearnConnection::PRESENTER}'", :source => :user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_modifier, :class_name => "User", :foreign_key => "last_modified_by"
  
  validates_presence_of :title, :description, :session_start, :session_length
  validates_format_of :recording, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix, :message => "must be a valid URL." 
  
  # calculate end of session time by adding session_length times 60 (session_length is in minutes) to session_start
  def calculate_end_time
    self.session_end = self.session_start + (self.session_length * 60)
  end
  
end