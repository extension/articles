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
  
  
  def self.get_sends_from_deliveries(delivery_date = Date.yesterday)
  end

    
    
end