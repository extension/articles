# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class BrontoMessage < ActiveRecord::Base
  has_many :bronto_deliveries
  has_many :bronto_sends
  
  @jitp_message_list = []
  
  class << self
    attr_accessor :jitp_message_list
  end
  
  def self.is_jitp_message(message_id,bronto_connection)
    if(self.jitp_message_list.blank?)
      self.jitp_message_list = bronto_connection.read_messages_for_delivery_group_id BrontoConnection::JITP_DELIVERY_GROUP
    end
    self.jitp_message_list.include?(message_id)
  end
  
  def self.get_message_for_id(message_id,bronto_connection)
    if(message = self.find_by_id(message_id))
      message
    else
      return_message = bronto_connection.read_message_for_id message_id
      message = self.new(:message_name => return_message[:name], :is_jitp => self.is_jitp_message(message_id,bronto_connection))
      message.id = message_id
      message.save
    end
    message
  end
        
end