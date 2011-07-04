# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class BrontoDelivery < ActiveRecord::Base
  has_many :bronto_sends
  belongs_to :bronto_message
  
  def self.get_sent_deliveries_for_date(date,bronto_connection)
    returned_deliveries = bronto_connection.read_sent_deliveries_on(date)
    deliveries_list = []
    returned_deliveries.each do |return_delivery|
      delivery = self.new(:bronto_message_id => return_delivery[:message_id], :status => return_delivery[:status], :start => return_delivery[:start])
      delivery.id = return_delivery[:id]
      begin
        delivery.save
      rescue ActiveRecord::StatementInvalid => e
        if(!(e.to_s =~ /duplicate/i))
          raise
        else
          delivery = BrontoDelivery.find_by_id(return_delivery[:id])
        end
      end
      if(delivery)
        deliveries_list << delivery
      end
    end
    
    # go through and get the messages if we don't have them and the sends as well.
    deliveries_list.each do |bronto_delivery|
      bronto_delivery.bronto_message = BrontoMessage.get_message_for_id(bronto_delivery.bronto_message_id,bronto_connection)
      if(!bronto_delivery.bronto_message.nil? and bronto_delivery.bronto_message.is_jitp?)
        # update the sends (which will update the contacts)
        sends_list = BrontoSend.get_sends_for_delivery(bronto_delivery,bronto_connection)
      end
    end
  end
    
end