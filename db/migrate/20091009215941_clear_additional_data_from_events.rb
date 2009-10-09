class ClearAdditionalDataFromEvents < ActiveRecord::Migration
  def self.up
    etypes_to_delete_additionaldata_for = [UserEvent::LOGIN_LOCAL_FAILED,UserEvent::LOGIN_LOCAL_SUCCESS,UserEvent::LOGIN_API_SUCCESS,UserEvent::LOGIN_API_FAILED]
    profile_events_to_delete = ['signup','initialsignup','interests updated','profile updated','other emails updated','social networks updated']
    profile_event_string = profile_events_to_delete.map{|s| "'#{s}'"}.join(',')
    execute "UPDATE user_events SET user_events.additionaldata = NULL where user_events.etype IN (#{etypes_to_delete_additionaldata_for.join(',')})"
    execute "UPDATE user_events SET user_events.additionaldata = NULL where user_events.etype = #{UserEvent::PROFILE} and user_events.description IN (#{profile_event_string})"
  end

  def self.down
  end
end
