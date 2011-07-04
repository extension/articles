# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class BrontoRecipient < ActiveRecord::Base
  has_many :bronto_sends
  
  
  def self.get_recipient_for_id(contact_id,bronto_connection)
    if(recipient = self.find_by_id(contact_id))
      recipient
    else
      return_recipient = bronto_connection.read_contact_for_id contact_id
      recipient = self.new(:email => return_recipient[:email])
      recipient.id = contact_id
      recipient.save
    end
    recipient
  end
end