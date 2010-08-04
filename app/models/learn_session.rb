# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
class LearnSession < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  include ERB::Util
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  
  DEFAULT_TIMEZONE = 'America/New_York'
  
  has_shared_tags  # include scopes for shared tags
  
  before_save :calculate_end_time
  
  has_many :learn_connections, :dependent => :destroy
  has_many :users, :through => :learn_connections, :select => "learn_connections.connectiontype as connectiontype, users.*"
  has_many :presenters, :through => :learn_connections, :conditions => "learn_connections.connectiontype = '#{LearnConnection::PRESENTER}'", :source => :user
  has_many :public_users, :through => :learn_connections, :select => "learn_connections.connectiontype as connectiontype, public_users.*"
  has_many :cached_tags, :as => :tagcacheable
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :last_modifier, :class_name => "User", :foreign_key => "last_modified_by"
  
  validates_presence_of :title, :description, :session_start, :session_length, :time_zone, :location
  validates_format_of :recording, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix, :message => "must be a valid URL." 
  
  ordered_by :orderings => {'Newest to oldest' => 'updated_at DESC'},
         :default => "#{self.table_name}.session_start ASC"
  
  
   # override timezone writer/reader
   # returns Eastern by default, use convert=false
   # when you need a timezone string that mysql can handle
   def time_zone(convert=true)
     tzinfo_time_zone_string = read_attribute(:time_zone)
     if(tzinfo_time_zone_string.blank?)
       tzinfo_time_zone_string = DEFAULT_TIMEZONE
     end

     if(convert)
       reverse_mappings = ActiveSupport::TimeZone::MAPPING.invert
       if(reverse_mappings[tzinfo_time_zone_string])
         reverse_mappings[tzinfo_time_zone_string]
       else
         nil
       end
     else
       tzinfo_time_zone_string
     end
   end

   def time_zone=(time_zone_string)
     mappings = ActiveSupport::TimeZone::MAPPING
     if(mappings[time_zone_string])
       write_attribute(:time_zone, mappings[time_zone_string])
     else
       write_attribute(:time_zone, nil)
     end
   end
    
  # calculate end of session time by adding session_length times 60 (session_length is in minutes) to session_start
  def calculate_end_time
    self.session_end = self.session_start + (self.session_length * 60)
  end
  
  def connected_users(connectiontype)
    if[LearnConnection::PRESENTER,LearnConnection::INTERESTED,LearnConnection::ATTENDED].include?(connectiontype)
      self.users.find(:all, :conditions => "learn_connections.connectiontype = '#{connectiontype}'")
    else
      return []
    end
  end
  
  def event_concluded?
    if(!self.session_end.blank?)
      return (Time.now.utc > self.session_end)
    else
      return false
    end
  end
  
  def event_started?(offset = 15.minutes)
    if(!self.session_start.blank?)
      return (Time.now.utc > self.session_start - offset)
    else
      return false
    end
  end
  
  def to_atom_entry
    t_start = self.session_start.in_time_zone(self.time_zone)
    
    content = self.description + "\n\n"
    content << "Location: " + self.location + "\n\n" if !self.location.blank?
    content << "Session Start: " + t_start.strftime("%B %e, %Y at %l:%M %p %Z") + "\n" +
               "Session Length: " + self.session_length.to_s + " minutes\n"
    content << "Recording: " + self.recording if !self.recording.blank?
    
    content = word_wrap(simple_format(auto_link(content, :all, :target => "_blank")))
    
    Atom::Entry.new do |e|
      e.title = Atom::Content::Html.new(self.title)
      e.links << Atom::Link.new(:type => "text/html", :rel => "alternate", :href => self.id_and_link)
      e.id = self.id_and_link
      e.updated = self.updated_at
      # could just as well use just .tags - but just in case we tag it in some other manner
      e.categories = self.tags_by_ownerid_and_kind(User.systemuserid,Tagging::SHARED).map{|tag| Atom::Category.new({:term => tag.name, :scheme => url_for(:controller => 'main', :action => 'index')})}
      e.content = Atom::Content::Html.new(content)
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