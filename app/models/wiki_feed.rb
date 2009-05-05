# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'timeout'
require 'open-uri'
require 'rexml/document'
require 'net/http'

class WikiFeed < Subscriber

  @@loadfromfile = false
  @@feedfile = 'undefined'
  cattr_accessor :loadfromfile, :feedfile

  def self.latest
    # objects_from_feed_tools
    objects_via_atom
  end
  
  private
  def self.base_url_with_objects
     AppConfig.configtable['host_wikiarticle'] + AppConfig.configtable['path_wikiarticlefeed']
  end

  def self.retrieve_wikis
    WikiFeed.retrieve_each { | each | 
      each.save! 
    } 
  end

  def self.url_for_time(time)
    time.xmlschema
  end

  def self.class_to_create
    Article
  end

  def self.objects_via_atom
    if(@@loadfromfile)
      fetch_atom_feed(@@feedfile).collect { |entry| class_to_create.from_atom_entry(entry) }  
    else
      fetch_atom_feed.collect { |entry| class_to_create.from_atom_entry(entry) }
    end
  end
end
