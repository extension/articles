class CopyRetiredReasonToUser < ActiveRecord::Migration
  def self.up
    # first, let's normalize the data to be a serialized field if not.
    execute "UPDATE admin_events SET data = CONCAT('---\n:extensionid: ',LOWER(data)) where event = 4 and data NOT LIKE '%---%'"
    # go through all retired admin_events, get the data, merge with the additionaldata on the account
    retired_events = AdminEvent.all(:conditions => {:event => AdminEvent::RETIRE_ACCOUNT})
    retired_events.each do |event|
      if(!event.data.nil? and !event.data[:extensionid].blank?)    
        find_user = event.data[:extensionid].downcase
        if(!event.data[:reason].blank?)
          reason = event.data[:reason]
        else
          reason = 'unknown'
        end
        
        if(u = User.find_by_login(find_user))
          if(u.additionaldata.blank?)
            u.update_attribute(:additionaldata, {:retired_by => event.user.id, :retired_reason => reason})
          else
            u.update_attribute(:additionaldata, u.additionaldata.merge({:retired_by => event.user.id, :retired_reason => reason}))
          end
        end
      end
    end 
  end

  def self.down
  end
end
