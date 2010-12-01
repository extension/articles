# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'

class PublicUser < Account
  has_many :responses
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/
  attr_protected :password 
  
  has_many :learn_connections
  has_many :learn_sessions, :through => :learn_connections, :select => "learn_connections.connectiontype as connectiontype, learn_sessions.*"
  
  
  def first_name
    if(first_name = read_attribute(:first_name))
      return first_name
    else
      return 'Anonymous'
    end
  end
  
  def last_name
    if(last_name = read_attribute(:last_name))
      return last_name
    else
      return 'Guest'
    end
  end
  
  def update_connection_to_learn_session(learn_session,connectiontype,connected=true)
    connection = self.learn_connections.find(:first, :conditions => "connectiontype = #{connectiontype} and learn_session_id = #{learn_session.id}")
    if(!connection.nil?)
      if(!connected)
        connection.destroy
      end
    elsif(connected == true)
      LearnConnection.create(:learn_session_id => learn_session.id, :user_id => self.id, :connectiontype => connectiontype, :email => self.email)
    end
  end
  
end