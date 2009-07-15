# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class EventsController < ApplicationController
  
  def index    
    set_title('Calendar', 'Check out our calendar to see what exciting events might be happening in your neighborhood.')
    set_titletag('eXtension - Calendar of Events')    
    @results  =  Event.monthly(get_calendar_month).ordered.in_states(params[:state]).tagged_with_content_tag(@category.name)
    @youth = true if @topic and @topic.name == 'Youth'
    render :action => 'events'
  end

  def detail
    @event = Event.find(params[:id])
    return unless @event
    @published_content = true
    @community_tags = @event.tags.community_content_tags
    @youth = true if @topic and @topic.name == 'Youth'
    set_title("#{@event.title.titleize} - eXtension Event",  @event.title.titleize)
    set_titletag("#{@event.title.titleize} - eXtension Event")
    
    flash.now[:googleanalytics] = request.request_uri + "?" + @community_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.category }.join('+').gsub(' ','_') if @community_tags and @community_tags.length > 0
  end
  
  private
  
  def get_calendar_month
    todays_date = Date.today
    if params[:year] && params[:month]
      begin
        month = Date.civil(params[:year].to_i, params[:month].to_i, 1)
      rescue
        month = Date.civil(todays_date.year, todays_date.month, 1)
      end
    else
      month = Date.civil(todays_date.year, todays_date.month, 1)
    end
    
    return month
  end

end
