# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AnnotationEvent < ActiveRecord::Base
  belongs_to :person
  belongs_to :annotation, :primary_key => :url
  serialize :additionaldata
  
  URL_ADDED = 'added'
  URL_DELETED = 'deleted'
  
  def url
    return self.annotation_id
  end
  
  def to_atom_entry
    Atom::Entry.new do |e|
      e.title = Atom::Content::Html.new(self.title)
      e.links << Atom::Link.new(:type => "text/html", :rel => "alternate", :href => self.id_and_link)
      e.authors << Atom::Person.new(:name => 'Contributors')
      e.id = self.id_and_link
      e.updated = self.source_updated_at
      e.categories = self.content_tag_names.map{|name| Atom::Category.new({:term => name, :scheme => url_for(:controller => 'main', :action => 'index')})}
      e.content = Atom::Content::Html.new(self.content)
    end
  end
  
  def id_and_link
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
      default_url_options[:port] = default_port
    end
    annotation_event_page_url(:id => self.id.to_s)
  end
  
  def self.log_event(opts)
    # ip address
    if(opts[:ip].nil?)
      opts[:ip] = AppConfig.configtable['request_ip_address']
    end
    
    AnnotationEvent.create(opts)
  end

end