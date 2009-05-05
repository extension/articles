# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class XCal < Subscriber

  def self.latest
    # objects_from_feed_tools
    objects_via_atom
  end

  private
  def self.base_url_with_objects
    AppConfig.configtable['events_feed']
  end
  
  def self.class_to_create
    Event
  end
  
  def self.retrieve_events
    XCal.retrieve_each { | event | event.deleted ? event.destroy : event.save! }
  end
  
  def self.objects_via_atom
    fetch_atom_feed.collect { |entry| class_to_create.from_atom_entry(entry) }
  end
  
end
