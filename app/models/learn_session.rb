# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
class LearnSession < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  
  before_save :calculate_end_time
  
  has_many :learn_connections
  has_many :users, :through => :learn_connections, :select => "learn_connections.connectiontype as connectiontype, users.*"
  has_many :presenters, :through => :learn_connections, :conditions => "learn_connections.connectiontype = '#{LearnConnection::PRESENTER}'", :source => :user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_modifier, :class_name => "User", :foreign_key => "last_modified_by"
  
  validates_presence_of :title, :description, :session_start, :session_length, :time_zone
  validates_format_of :recording, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix, :message => "must be a valid URL." 
  
  ordered_by :orderings => {'Newest to oldest' => 'updated_at DESC'},
         :default => "#{self.table_name}.session_start ASC"
  
  named_scope :tagged_with_shared_tags, lambda { |tagliststring|
    
    includelist= Tag.castlist_to_array(tagliststring,true,false)
    
    if(!includelist.empty?)
      # get a list of all the id's tagged with the includelist
      includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tag_kind = #{Tagging::SHARED}) AND (taggings.taggable_type = '#{self.name}')"
      includetaggings = Tagging.find(:all, :include => :tag, :conditions => includeconditions, :group => "taggable_id", :having => "COUNT(taggable_id) = #{includelist.size}").collect(&:taggable_id)
      taggings_we_want = includetaggings
    end
    
    if(!taggings_we_want.empty?)
      {:conditions => "id IN (#{taggings_we_want.join(',')})"}  
    else
      {}
    end
  }
  
  # calculate end of session time by adding session_length times 60 (session_length is in minutes) to session_start
  def calculate_end_time
    self.session_end = self.session_start + (self.session_length * 60)
  end
  
  def event_concluded?
    return (Time.now.utc > self.session_end)
  end
  
  def event_started?
    return (Time.now.utc > self.session_start)
  end
  
  
  def to_atom_entry
    Atom::Entry.new do |e|
      e.title = Atom::Content::Html.new(self.title)
      e.links << Atom::Link.new(:type => "text/html", :rel => "alternate", :href => self.id_and_link)
      e.id = self.id_and_link
      e.updated = self.updated_at
      e.categories = self.tag_list.split(',').each { |cat| Atom::Category.new(cat.strip) }
      e.content = Atom::Content::Html.new(self.description)
    end
  end
  
  def id_and_link(only_path = false)
   default_url_options[:host] = AppConfig.get_url_host
   default_url_options[:protocol] = AppConfig.get_url_protocol
   if(default_port = AppConfig.get_url_port)
    default_url_options[:port] = default_port
   end
   
   learn_session_url(:id => self.id, :only_path => only_path)
  end
end