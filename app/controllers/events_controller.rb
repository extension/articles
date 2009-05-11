# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class EventsController < DataController
  
  def index    
    set_title('Calendar', 'Check out our calendar to see what exciting events might be happening in your neighborhood.')
    set_titletag('eXtension - Calendar of Events')    
    @results  =  Event.monthly(get_month).ordered.in_states(params[:state]).tagged_with_content_tags(@category.name)
    @youth = true if @topic and @topic.name == 'Youth'
    render :action => 'events'
  end

  def detail
    @event = Event.find(params[:id])
    return unless @event
    @published_content = true
    @community_tags = @event.tags.community
    @youth = true if @topic and @topic.name == 'Youth'
    set_title("#{@event.title.titleize} - eXtension Event",  @event.title.titleize)
    set_titletag("#{@event.title.titleize} - eXtension Event")
    
    flash.now[:googleanalytics] = request.request_uri + "?" + @community_tags.collect{|tag| tag.community }.uniq.compact.collect { |community| community.category }.join('+').gsub(' ','_') if @community_tags and @community_tags.length > 0
  end

end
