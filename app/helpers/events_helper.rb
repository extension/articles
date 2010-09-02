module LearnHelper

  def format_time(event)
    if !event.time_zone.blank?
      return nil if event.blank?
    
      # if user has not selected a timezone to have things displayed in...
      if (@currentuser.nil? or !@currentuser.has_time_zone?)
        return event.start.in_time_zone(event.time_zone) 
        # if the user has selected a timezone in people, the time will auto-display correctly in their preferred tz
      else
        return event.start
      end
    else
      return event.start
    end
  end

end