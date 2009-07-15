# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'cgi'
require 'mofo'

class Event < ActiveRecord::Base
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
  
  # so that we can generate URLs out of the model to convert it to an atom entry
  include ActionController::UrlWriter
  default_url_options[:host] = AppConfig.configtable['url_options']['host']
  default_url_options[:port] = AppConfig.get_url_port
  
  
  # in the event we do a refreshall
  
  
  def self.create_or_update_from_atom_entry(entry)
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
        
    if vevent.properties.include?('status')
      if vevent.status == 'CANCELLED'
        returndata = [item.xcal_updated_at, 'delete', nil]
        item.destroy
        return returndata
      end
    end
    
    if(item.new_record?)
      returndata = [item.xcal_updated_at, 'add']
    else
      returndata = [item.xcal_updated_at, 'update']
    end
    item.save!
    item.tag_with(entry.categories,User.systemuserid,Tag::CONTENT)
    returndata << item
    return returndata
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
    
  def local_to?(state)
    return true if state_abbreviations.include? state 
    return true if location && location.include?(state)
    
    false
  end
  
     
    # -----------------------------------
    # Class-level methods
    # -----------------------------------


    def self.retrieve_content(options = {})
       current_time = Time.now.utc
       
       refresh_all = (options[:refresh_all].nil? ? false : options[:refresh_all])
       feed_url = (options[:feed_url].nil? ? AppConfig.configtable['content_feed_events'] : options[:feed_url])

       updatetime = UpdateTime.find_or_create(self,'content')
       if(refresh_all)
         refresh_since = (options[:refresh_since].nil? ? AppConfig.configtable['content_feed_refresh_since'] : options[:refresh_since])
       else    
         refresh_since = updatetime.last_datasourced_at
       end
      
      # will raise errors on failure
      xmlcontent = self.fetch_url_content(self.build_feed_url(feed_url,refresh_since,false))

      # create new Events from the atom entries
      added_events = 0
      updated_events = 0
      deleted_events = 0
      last_updated_event_time = refresh_since
      
      atom_entries =  AtomEntry.entries_from_xml(xmlcontent)
      if(!atom_entries.blank?)
        atom_entries.each do |entry|
          (object_update_time, object_op, object) = self.create_or_update_from_atom_entry(entry)
          # get smart about the last updated time
          if(object_update_time > last_updated_event_time )
            last_updated_event_time = object_update_time
          end
        
          case object_op
          when 'delete'
            deleted_events += 1
          when 'update'
            updated_events += 1
          when 'add'
            added_events += 1
          end
        end
      
        # update the last retrieval time, add one second so we aren't constantly getting the last record over and over again
        updatetime.update_attribute(:last_datasourced_at,last_updated_event_time + 1)
      end
      
      return {:added => added_events, :deleted => deleted_events, :updated => updated_events}
    end
   
end
