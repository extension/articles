# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'cgi'
require 'mofo'

class Event < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model to convert it to an atom entry
  extend DataImportContent  # utility functions for importing event content

  #-- Rails 2.1 dependent stuff
  include HasStates
  has_content_tags
  ordered_by :default => "#{quoted_table_name}.date ASC"
  
  # Get all events in a given month, this month if no month is given
  named_scope :monthly, lambda { |*date|
    
    # Default to this month if not date is given
    date = date.flatten.first ? date.flatten.first : Date.today    
    {:conditions => ['start >= ? AND start <= ?', date.to_time.beginning_of_month, date.to_time.end_of_month] }
  }
  
  # Get all events starting after (and including) the given date
  named_scope :after, lambda { |date| { :conditions => ['start >= ?', date] } }
  
  # Get all events within x number of days from the given date
  named_scope :within, lambda { |interval, date| { :conditions => ['start >= ? AND start < ?', date, date + interval] } }
  
  def self.get_cache_key(method_name,optionshash={})
    optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
    cache_key = "#{self.name}::#{method_name}::#{optionshashval}"
    return cache_key
  end
  
  # helper method for main page items
  def self.main_calendar_list(options = {},forcecacheupdate=false)
    cache_key = self.get_cache_key(this_method,options)
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      if(!options[:within_days].nil?)
        findoptions = {:conditions => ['start >= ? AND start < ?', options[:calendar_date], options[:calendar_date] + options[:within_days]]}
      else
        findoptions = {:conditions => ['start >= ?', options[:calendar_date]]}
      end
      
      if(!options[:limit].nil?)
        findoptions.merge!({:limit => options[:limit]})
      end
      
      if(options[:content_tag].nil?)
        Event.ordered.all(findoptions)
      else
        Event.tagged_with_content_tag(options[:content_tag].name).ordered.all(findoptions)
      end
    end
  end 
    
  def self.create_or_update_from_atom_entry(entry,datatype = "ignored")
    vevent = hCalendar.find(:first => {:text => entry.content.to_s})
    item = self.find_by_id(vevent.uid) || self.new
    
    # hcalendar attributes:
    #   Required:
    #     * dtstart (ISO date)
    #     * summary 
    # 
    #   Optional:
    #     * location
    #     * url
    #     * dtend (ISO date), duration (ISO date duration)
    #     * rdate, rrule
    #     * category, description
    #     * uid
    #     * geo (latitude, longitude)
    #
    # mofo properties:
    #   global
    #     :tags
    #   vevent
    #     :class, :description, :dtend, :dtstamp, :dtstart,
    #     :duration, :status, :summary, :uid, :last_modified, 
    #     :url => :url, :location => [ HCard, Adr, Geo, String ]
    
    item.id = vevent.uid
    
    item.title = vevent.summary
    item.description = CGI.unescapeHTML(vevent.description)
    
    if entry.updated.nil?
      updated = Time.now.utc
    else
      updated = entry.updated
    end
    item.xcal_updated_at = updated
    
    item.start = vevent.dtstart
    item.date = vevent.dtstart.strftime('%Y-%m-%d')
    item.time = vevent.dtstart.strftime('%H:%M:%S')
    
    if vevent.properties.include?("dtend")
      duration = (vevent.dtend - vevent.dtstart) / (24 * 60 * 60) # result in days
      item.duration = duration.to_int
    end
        
    loco = vevent.location.split('|')
    item.location = loco[0]
    item.coverage = loco[1]
    item.state_abbreviations = loco[2]
        
    if vevent.properties.include?('status')
      if vevent.status == 'CANCELLED'
        returndata = [item.xcal_updated_at, 'deleted', nil]
        item.destroy
        return returndata
      end
    end
    
    if(item.new_record?)
      returndata = [item.xcal_updated_at, 'added']
    else
      returndata = [item.xcal_updated_at, 'updated']
    end
    item.save!
    
    if(!entry.categories.blank?)
      item.replace_tags(entry.categories.map(&:term),User.systemuserid,Tag::CONTENT)      
    end
    
    returndata << item
    return returndata
  end
  
  def id_and_link
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
      default_url_options[:port] = default_port
    end
    events_page_url(:id => self.id.to_s)
  end
  
  def to_atom_entry
    xml = Builder::XmlMarkup.new(:indent => 2)
    
    xml.entry do
      xml.title(self.title, :type => 'html')
      xml.content(self.description, :type => 'html')
      
      self.tag_list.each do |cat|
        xml.category "term" => cat  
      end
      
      xml.author { xml.name "Contributors" }
      xml.id(self.id_and_link)
      xml.link(:rel => 'alternate', :type => 'text/html', :href => self.id_and_link)
      xml.updated self.xcal_updated_at.atom
    end
  end 
  
  
  def self.get_events_for_days(events, start_date, end_date,&block)
    start_date.upto(end_date) {|date|
      events_for_day = []
      for event in events
        events_for_day.push(event) if event.date == date
      end
      block.call(date,events_for_day)
    }
  end
  
  def has_map?
    if !location || location.downcase.match(/web based|http|www|\.com|online/)
      false
    else
      true
    end
  end
    
  def local_to?(state)
    return true if state_abbreviations.include? state 
    return true if location && location.include?(state)
    
    false
  end
  
end
