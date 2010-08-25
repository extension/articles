# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class EventsController < ApplicationController
  before_filter :set_content_tag_and_community_and_topic
  
  layout 'pubsite'
  
  def index    
    set_title('Calendar', 'Check out our calendar to see what exciting events might be happening in your neighborhood.')
    if(!@content_tag.nil?)
      set_titletag("eXtension - #{@content_tag.name} - Calendar of Events")
      @results  =  Event.monthly(get_calendar_month).ordered.in_states(params[:state]).tagged_with_content_tag(@content_tag.name)      
    else
      set_titletag('eXtension - all - Calendar of Events')
      @results  =  Event.monthly(get_calendar_month).ordered.in_states(params[:state]).all
    end    
    @youth = true if @topic and @topic.name == 'Youth'
    render :action => 'events'    
  end

  def detail
    @event = Event.find(params[:id])
    return unless @event
    @published_content = true
    
    # handle events w/ timezones
    if !@event.time_zone.blank?
      # convert time stored in db to desired tz 
      @event_start = @event.start.in_time_zone(@event.time_zone)
    else
      @event_start = @event.start
    end
    
    # get the tags on this event that correspond to community content tags
    event_content_tags = @event.tags.content_tags
    if(!event_content_tags.blank?)
      # is this event tagged with youth?
      @youth = true if event_content_tags.map(&:name).include?('youth')
      
      # get the tags on this article that are content tags on communities
      @community_content_tags = (Tag.community_content_tags & event_content_tags)
    
      if(!@community_content_tags.blank?)
        @sponsors = Sponsor.tagged_with_any_content_tags(@community_content_tags.map(&:name)).prioritized
        # loop through the list, and see if one of these matches my @community already
        # if so, use that, else, just use the first in the list
        use_content_tag = @community_content_tags.rand
        @community_content_tags.each do |community_content_tag|
          if(community_content_tag.content_community == @community)
            use_content_tag = community_content_tag
          end
        end
      
        @community = use_content_tag.content_community
        @youth = true if @community and @community.topic and @community.topic.name == 'Youth'
      end
    end    
        
    set_title("#{@event.title.titleize} - eXtension Event",  @event.title.titleize)
    set_titletag("#{@event.title.titleize} - eXtension Event")
    flash.now[:googleanalytics] = request.request_uri + "?" + @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.join('+').gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
    flash.now[:googleanalyticsresourcearea] = @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.first.gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
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
