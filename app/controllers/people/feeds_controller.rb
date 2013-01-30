# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::FeedsController < ApplicationController

  
  # feed generating methods
  
  def showuser
    show_feed_removal_output    
  end
  
  def community
    show_feed_removal_output
  end
  
  def communities
    show_feed_removal_output
  end
  
  
  def institution
    show_feed_removal_output
  end
  
  def location
    show_feed_removal_output
  end
  
  def position
    show_feed_removal_output
  end
  
  def list
    show_feed_removal_output
  end   
    
  def application
    show_feed_removal_output
  end  
    
  private
    def show_feed_removal_output(feedoptions={})
      peoplebot = User.find(1)
      feed = Atom::Feed.new do |f|
        f.title = "eXtension Activity Feed Error"
        # TODO : link over to activity?
        f.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => feedoptions[:alternate] || (request.protocol + request.host_with_port))
        f.links << Atom::Link.new(:rel => 'self', :type => 'application/atom+xml', :href => feedoptions[:self] || request.url)
        f.updated = Time.now.utc.xmlschema
        f.id = make_atom_feed_id()
        f.entries << Atom::Entry.new do |e|
          e.authors << Atom::Person.new(:name => peoplebot.fullname, :email => peoplebot.email)
          e.title = "eXtension Activity Feed Error"
          e.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => feedoptions[:alternate] || (request.protocol + request.host_with_port))
          e.id = make_atom_entry_id("Invalid")
          e.updated = Time.now.utc.xmlschema
          errormsg = "The eXtension People is in the process of transitioning to a new software platform. The existing atom feeds will not be ported. After the transition, please visit the new application for feed options."
          e.content = Atom::Content::Html.new("<p>#{errormsg}</p>")
        end
      end

      render :xml => feed.to_xml    
    end
    
    def make_atom_feed_id(schema_date=Time.now.year)
      "tag:#{request.host},#{schema_date}:#{request.request_uri.split(".")[0]}"
    end
    
    def make_atom_entry_id(obj,schema_date=Time.now.year)
      if(obj.class != "String")
        "tag:#{request.host},#{schema_date}:#{obj.class}/#{obj.id}"
      else
        "tag:#{request.host},#{schema_date}:#{obj}"
      end
    end
end