# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'cgi'
require 'mofo'

class Event < ActiveRecord::Base
  
  #-- Rails 2.1 dependent stuff
  include HasStates
  has_categories
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
  
  #-- Older stuff
  
  include ActionController::UrlWriter
  default_url_options[:host] = AppConfig.configtable['urlwriter_host']
  default_url_options[:port] = AppConfig.configtable['urlwriter_port'] unless AppConfig.configtable['urlwriter_port'] == 80
    
  def self.from_hash(hash)
    item = self.find_by_id(hash['id']) || self.new
    
    hash.keys.each { | key | item.set_attribute(key, hash[key]) }
    item
  end
  
  def self.from_atom_entry(entry)
    vevent = hCalendar.find(:first => {:text => entry.content})
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
    item.taggings.each { |t| t.destroy }
    item.cached_tag_list = []
    
    item.title = vevent.summary
    item.description = CGI.unescapeHTML(vevent.description)
    
    if entry.updated.nil?
      updated = Time.now.utc
    else
      updated = Time.parse(entry.updated)
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
    
    assign_tags(item, entry)
    item.deleted = 0
    
    if vevent.properties.include?('status')
      if vevent.status == 'CANCELLED'
        item.deleted = 1
      end
    end
    
    item.save!
    item
  end
  
  def id_and_link
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
  
  def set_attribute(attribute, value)
    if (attribute == 'updated_at')
      self.send("xcal_#{attribute}=", value)  
    else
      set_standard_attribute(attribute, value)
    end
  end
  
  def local_to?(state)
    return true if state_abbreviations.include? state 
    return true if location && location.include?(state)
    
    false
  end
  
  private
  
   def add_tags_from_value(value)
     tags = Community.generate_tags_and_communities(value)
     tag_list.add(*tags) #tags have already been created, we are just linking to them
   end

   def set_standard_attribute(attribute, value)     
     if attribute == "categories"
       add_tags_from_value(value)
     else
       self.send("#{attribute}=", value)  
     end
   end
   
   def self.assign_tags(event, feed_item)
     event.tag_list.add(*feed_item.categories)
   end
   
end
