# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module EventsHelper

  def format_event_time(event)
    return nil if event.blank?
    
    if !event.time_zone.blank?
      # if user has not selected a timezone to have things displayed in...
      if (@currentuser.nil? or !@currentuser.has_time_zone?)
        return event.start.in_time_zone(event.time_zone) 
        # if the user has selected a timezone in people, the time will auto-display correctly in their preferred tz
        # if the user did not select a tz in people, it will just display in it's own tz
      else
        return event.start
      end
    else
      return event.start
    end
  end

end