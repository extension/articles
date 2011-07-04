# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class BrontoSend < ActiveRecord::Base
  belongs_to :bronto_delivery
  belongs_to :bronto_message
  belongs_to :bronto_recipient
  
  
  def self.get_sends_for_delivery(bronto_delivery,bronto_connection)
    sends_list = []
    return_sends = bronto_connection.read_sends_for_delivery(bronto_delivery.id)
    return_sends.each do |returned_send|
      begin
        send = self.create(:bronto_delivery_id => bronto_delivery.id, :bronto_message_id => bronto_delivery.bronto_message_id, :bronto_recipient_id => returned_send[:contact_id], :sent => returned_send[:created])
        sends_list << send
      rescue
        # do nothing
      end
    end
    
    # contact updates for each send if we don't have them already
    sends_list.each do |send|
      send.bronto_recipient = BrontoRecipient.get_recipient_for_id(send.bronto_recipient_id,bronto_connection)
    end
    sends_list
  end
  
  
  def self.get_clicks_since(date,bronto_connection)
    clicks = bronto_connection.read_click_activities_after(date)
    clicks.each do |click|
      if(bronto_send = BrontoSend.where(:bronto_recipient_id => click[:contact_id]).where(:bronto_delivery_id => click[:delivery_id]).where(:bronto_message_id => click[:message_id]).first)
        bronto_send.update_attributes(:url => click[:link_url],:clicked => click[:activity_date])
      end
    end
  end    
    
end