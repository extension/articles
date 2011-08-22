# === COPYRIGHT:
# Copyright (c) 2005-2011 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'mofo'
class Page < ActiveRecord::Base
  # for events
  attr_accessor :event_time, :event_date
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  include TaggingScopes
  
  
  URL_TITLE_LENGTH = 100
  
  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2
  
   
  after_create :store_content, :create_primary_link
  before_save  :set_url_title
  before_update :check_content
  before_destroy :change_primary_link
  
  has_content_tags
  ordered_by :orderings => {'Events Default' => 'event_start ASC', 'Newest to oldest events' => 'event_start DESC', 'Newest to oldest'=> "source_updated_at DESC"},
                            :default => "source_updated_at DESC"
         
  has_one :primary_link, :class_name => "Link"
  has_many :linkings
  has_many :links, :through => :linkings
  has_many :bucketings
  has_many :content_buckets, :through => :bucketings
  has_one :link_stat
  belongs_to :page_source
  has_many :cached_tags, :as => :tagcacheable
  

  named_scope :bucketed_as, lambda{|bucketname|
   {:include => :content_buckets, :conditions => "content_buckets.name = '#{ContentBucket.normalizename(bucketname)}'"}
  }
  
  named_scope :broken_links, :conditions => {:has_broken_links => true}

  named_scope :indexed, :conditions => {:indexed => INDEXED}
  named_scope :articles, :conditions => {:datatype => 'Article'}
  named_scope :news, :conditions => {:datatype => 'News'}
  named_scope :faqs, :conditions => {:datatype => 'Faq'}
  named_scope :events, :conditions => {:datatype => 'Event'}
  named_scope :newsicles, :conditions => ["(datatype = 'Article' OR datatype = 'News')"]
  
  
  named_scope :by_datatype, lambda{|datatype|
   if(datatype.is_a?(Array))
     datatypes_list = datatype.map{|d| "'#{d}'"}.join(',')
     {:conditions => "datatype IN (#{datatypes_list})"}
   else
     {:conditions => "datatype = '#{datatype}'"}
   end
  }
  
  # Get all events in a given month, this month if no month is given
  named_scope :monthly, lambda { |*date|
    
    # Default to this month if not date is given
    date = date.flatten.first ? date.flatten.first : Date.today    
    {:conditions => ['datatype = ? AND (event_start >= ? AND event_start <= ?)', 'event',date.to_time.beginning_of_month, date.to_time.end_of_month] }
  }
  
  # Get all events starting after (and including) the given date
  named_scope :after, lambda { |date| { :conditions => ['datatype = ? AND event_start >= ?', 'event',date] } }
  
  # Get all events within x number of days from the given date
  named_scope :within, lambda { |interval, date| { :conditions => ['datatype = ? AND (event_start >= ? AND event_start < ?)', 'event', date, date + interval] } }
  
  named_scope :in_states, lambda { |*states| 
    states = states.flatten.compact.uniq.reject { |s| s.blank? }
    return {} if states.empty?
    conditions = states.collect { |s| sanitize_sql_array(["state_abbreviations like ?", "%#{s.to_s.upcase}%"]) }.join(' AND ')
    {:conditions => "#{conditions} OR (state_abbreviations = '' and coverage = 'National')"}
  }
  
  named_scope :full_text_search, lambda{|options|
    match_string = options[:q]
    boolean_mode = options[:boolean_mode] || false
    if(boolean_mode)
      {:select => "#{self.table_name}.*, MATCH(title,content) AGAINST (#{sanitize(match_string)}) as match_score", :conditions => "MATCH(title,content) AGAINST (#{sanitize(match_string)} IN BOOLEAN MODE)"}
    else
      {:select => "#{self.table_name}.*, MATCH(title,content) AGAINST (#{sanitize(match_string)}) as match_score", :conditions => ["MATCH(title,content) AGAINST (?)", sanitize(match_string)]}
    end
  }

  # returns a class::method::options string to use as a memcache key
  #
  # @param [String] method_name name of the method (or other string) to associate this cache with
  # @param [Hash] optionshash Hash of options, turned into a sha1 so we can have option-specific keys   
  # @return [String] string to use as a memcache key
  def self.get_cache_key(method_name,optionshash={})
   optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
   cache_key = "#{self.name}::#{method_name}::#{optionshashval}"
   return cache_key
  end
  
  def get_cache_key(method_name,optionshash={})
    optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
    cache_key = "#{self.id}::#{method_name}::#{optionshashval}"
    return cache_key
  end
  
  def is_copwiki_or_create?
    (self.source == 'copwiki' or self.source == 'create')
  end
  
  # syntactic sugar - returns true if the datatype is an article
  def is_article?
    (self.datatype == 'Article')
  end
    
  # syntactic sugar - returns true if the datatype is news
  def is_news?
    (self.datatype == 'News')
  end
  
  # syntactic sugar - returns true if the datatype is news or an article
  def is_newsicle?
    (self.datatype == 'News' or self.datatype == 'Article')
  end
  
  # syntactic sugar - returns true if the datatype is a faq
  def is_faq?
    (self.datatype == 'Faq')
  end
  
  def is_old_faq?
    # drupal faq conversion date is June 22, 2011
    (self.datatype == 'Faq') and (self.updated_at.to_date <= Date.parse('2011-06-22'))
  end
  
  # syntactic sugar - returns true if the datatype is an event
  def is_event?
    (self.datatype == 'Event')
  end
  
  # returns the number of links associated with this page, if updated_at > the link_stat for this page
  # it counts and updates the link_stat
  #
  # @return [Hash] keyed hash of the link counts for this page
  def link_counts(force_update = false)
    linkcounts = {:total => 0, :external => 0,:local => 0, :wanted => 0, :internal => 0, :broken => 0, :redirected => 0, :warning => 0}
    if(self.link_stat.nil? or force_update or self.updated_at > self.link_stat.updated_at)      
      self.links.each do |cl|
        linkcounts[:total] += 1
        case cl.linktype
        when Link::EXTERNAL
          linkcounts[:external] += 1
        when Link::INTERNAL
          linkcounts[:internal] += 1
        when Link::LOCAL
          linkcounts[:local] += 1
        when Link::WANTED
          linkcounts[:wanted] += 1
        end
      
        case cl.status
        when Link::BROKEN
          linkcounts[:broken] += 1
        when Link::OK_REDIRECT
          linkcounts[:redirected] += 1
        when Link::WARNING
          linkcounts[:warning] += 1
        end
      end
      if(self.link_stat.nil?)
        self.create_link_stat(linkcounts)
      else
        self.link_stat.update_attributes(linkcounts)
      end
    else
      linkcounts.keys.each do |key|
        linkcounts[key] = self.link_stat.send(key)
      end
    end
    return linkcounts
  end
  
  # mass update of the has_broken_links flag, looping through them all if needed is waaaaaay too slow
  def self.update_broken_flags
    # set all to false
    update_all("has_broken_links = 0")
    
    # get a list that have more than one broken link
    broken_list = count('links.id',:joins => :links,:conditions => "links.status IN (#{Link::WARNING},#{Link::BROKEN}) ",:group => "#{self.table_name}.id")
    broken_ids = broken_list.keys
    update_all("has_broken_links = 1", "id IN (#{broken_ids.join(',')})")    
  end

  # update broken flag for this page 
  def update_broken_flag
    broken_count = self.links.count(:conditions => "links.status IN (#{Link::WARNING},#{Link::BROKEN}) ")
    self.update_attribute(:has_broken_links,(broken_count > 0))
  end
  
  # given an array of categories, places the page into matching content buckets
  # 
  # @param [Array] categoryarray array of categories to match against bucket names    
  def put_in_buckets(categoryarray)
   namearray = []
   categoryarray.each do |name|
    namearray << ContentBucket.normalizename(name)
   end
   
   buckets = ContentBucket.find(:all, :conditions => "name IN (#{namearray.map{|n| "'#{n}'"}.join(',')})")
   # bucket as "notnews" if categoryarray doesn't include 'news' or 'originalnews'
   if(!categoryarray.include?('news') and !categoryarray.include?('originalnews'))
     buckets << ContentBucket.find_by_name('notnews')
   end
   
   # force news bucket if categoryarray includes 'originalnews'
   if(categoryarray.include?('originalnews'))
     buckets << ContentBucket.find_by_name('news')
   end
   self.content_buckets = buckets
  end
  
  # return an array of the content tags for this page, filtering out the blacklist
  # returns it from memcache or from an association call to the db
  # 
  # @return [Array] array of content tag names 
  # @param [Boolean] forcecacheupdate force caching update  
  def content_tags(forcecacheupdate = false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,{})
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.class.content_cache_expiry) do
     self.tags.content_tags.reject{|t| Tag::CONTENTBLACKLIST.include?(t.name) }.compact
   end
  end
  
  # return an array of the content tag names for this page, filtering out the blacklist
  # returns it from memcache or from an association call to the db (via self.content_tags)
  # 
  # @return [Array] array of content tag names 
  # @param [Boolean] forcecacheupdate force caching update  
  def content_tag_names(forcecacheupdate = false)
    self.content_tags(forcecacheupdate).map{|t| t.name}
  end
  
  def cached_content_tag_names
    if(self.cached_content_tags.blank?)
      self.cache_tags(User.systemuserid,Tagging::CONTENT)
    end
    cached_tag_list = self.cached_content_tags.split(Tag::JOINER)
    cached_tag_list.reject{|tagname| Tag::CONTENTBLACKLIST.include?(tagname) }.compact
  end
  
  def cached_tag_field(ownerid,kind)
    if(ownerid == User.systemuserid and kind == Tagging::CONTENT)
      return 'cached_content_tags'
    else
      return nil
    end
  end
  
  # return an array of the content tag names for this page, filtering out the blacklist and compared to the community content tags
  # returns it from memcache or from an association call to the db (via self.content_tags)
  # 
  # @return [Array] array of content tag names 
  # @param [Boolean] forcecacheupdate force caching update  
  def community_content_tags(forcecacheupdate = false)
    self.content_tags(forcecacheupdate) & Tag.community_content_tags({:launchedonly => true})   
  end
  
  def community_content_tag_names
    global_community_content_tag_names = Tag.community_content_tags({:launchedonly => true}).map(&:name)
    self.cached_content_tag_names & global_community_content_tag_names
  end
    
  # return a collection of the most recent news articles for the specified limit/content tag
  # will check memcache first
  # 
  # @return [Array<Page>] array/collection of matching pages
  # @param [Hash] options query options
  # @option options [Integer] :limit query limit
  # @option options [String] :content_tags string of content tags to search for (it could also an array or anything Tag.castlist_to_array takes)
  # @option options [Array] :datatypes array of datatypes to search for ['Article','Event','Faq','News] accepted
  # @option options [Date] :calendar_date for Events filtering
  # @option options [Integer] :within_days for Events filtering
  # @option options [String] :tag_operator 'and' or 'or' matching for content tags
  # @param [Boolean] forcecacheupdate force caching update
  def self.recent_content(options = {},forcecacheupdate=false)
    cache_key = self.get_cache_key(this_method,options)
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      if(options[:datatypes].nil? or options[:datatypes] == 'all')
        datatypes = ['Article','Faq','News','Event']
      elsif(options[:datatypes].is_a?(Array))
        datatypes = options[:datatypes]
      else
        datatypes = [options[:datatypes]]
      end    
      
      # build the scope
      recent_content_scope = Page.scoped({})
      recent_content_scope = recent_content_scope
      # datatypes
      datatype_conditions = self.datatype_conditions(datatypes)
      if(!datatype_conditions.blank?)
        recent_content_scope = recent_content_scope.where(datatype_conditions)
      end
      # content tags
      if(!options[:content_tags].nil?)
        if(options[:tag_operator] and options[:tag_operator] == 'and')
          recent_content_scope = recent_content_scope.tagged_with_all_content_tags(options[:content_tags])
        else
          recent_content_scope = recent_content_scope.tagged_with_any_content_tags(options[:content_tags])
        end
      elsif(!options[:content_tag].nil?)
        if(options[:content_tag].is_a?(Tag))
          tagname = options[:content_tag].name
        else
          tagname = options[:content_tag]
        end
        recent_content_scope = recent_content_scope.tagged_with_content_tag(options[:content_tag].name)
      end
      
      # limit?
      if(options[:limit])
        recent_content_scope = recent_content_scope.limit(options[:limit])
      end
      # ordering
      if(options[:order])
        recent_content_scope = recent_content_scope.ordered(options[:order])
      else
        recent_content_scope = recent_content_scope.ordered
      end
      recent_content_scope.all
    end
  end

  def self.datatype_conditions(datatypes,options = {})
    datatype_conditions = []
    datatypes.each do |dt|
      case dt
      when 'Article'
        datatype_conditions << "(datatype = 'Article')"
      when 'Faq'
        datatype_conditions << "(datatype = 'Faq')"
      when 'News'
        datatype_conditions << "(datatype = 'News')"
      when 'Event'
        calendar_date = options[:calendar_date] || Date.today
        if(options[:allevents])
          datatype_conditions << "(datatype = 'Event')"
        elsif(!options[:within_days].nil?)
          datatype_conditions << "(datatype = 'Event' and (event_start >= '#{calendar_date.to_s(:db)}' and event_start < '#{(calendar_date + options[:within_days]).to_s(:db)}'))"
        else
          datatype_conditions << "(datatype = 'Event' and event_start >= '#{calendar_date.to_s(:db)}')"
        end
      end
    end
    
    datatype_conditions.join(' OR ')
  end
  
  def self.content_type_conditions(content_types,options = {})
    datatypes = []
    content_types.each do |content_type|
      case content_type
      when 'faqs'
        datatypes << 'Faq'
      when 'articles'
        datatypes << 'Article'
      when 'events'
        datatypes << 'Event'
      when 'news'
        datatypes << 'News'
      end
    end
    self.datatype_conditions(datatypes,options)
  end
  
  

  def self.main_feature_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tag].nil?)
      self.newsicles.bucketed_as('feature').ordered.limit(options[:limit]).all 
    else
      self.newsicles.bucketed_as('feature').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
    end
   end
  end
  
  # get featured articles that are diverse across communities (ie. make sure only one article per community is returned up to limit # of articles).
  # created so that the homepage has featured articles across diverse areas so if multiple articles are published from a community at once, only one 
  # is chosen from that community for the home page.
  #
  # @param [Hash] options query options
  # @option options [Integer] :limit query limit
  # @option opts [ContentTag] :content_tag ContentTag to search for
  # @param [Boolean] forcecacheupdate force caching update
  def self.diverse_feature_list(options = {}, forcecacheupdate=false)
    # OPTIMIZE: keep an eye on this caching
    cache_key = self.get_cache_key(this_method,options)
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      communities_represented = []
      pages_to_return = []
      
      # get a list of launched communities
      launched_communitylist = Community.launched.all(:order => 'name')
      launched_community_ids = launched_communitylist.map(&:id).join(',')
      
      # limit to last AppConfig.configtable['recent_feature_limit'] days so we aren't pulling the full list every single time
      # converting to a date to take advantage of mysql query caching for the day
      only_since = Time.zone.now.to_date - AppConfig.configtable['recent_feature_limit'].day
      
      # get articles and their communities - joining them up by content tags
      # we have to do this group concat here because a given article may belong
      # to more than one community
      pagelist = self.find(
        :all, 
        :select => "#{self.table_name}.*, GROUP_CONCAT(communities.id) as community_ids_string", 
        :joins => [:content_buckets, {:tags => :communities}], 
        :conditions => "(datatype = 'Article' or datatype = 'News') AND DATE(#{self.table_name}.source_updated_at) >= '#{only_since.to_s(:db)}' and taggings.tagging_kind = #{Tagging::CONTENT} AND communities.id IN (#{launched_community_ids}) AND content_buckets.name = 'feature'", 
        :group => "#{self.table_name}.id",
        :order => "#{self.table_name}.source_updated_at DESC"
      )
                   
      pagelist.each do |page|
        community_ids = page.community_ids_string.split(',')
        
        if community_ids.length > 0
          # if we have already processed an article from the tags applied to this article, go to the next one
          if (community_ids & communities_represented) != []
            next
          else
            pages_to_return << page
            communities_represented.concat(community_ids)
          end
        else
          next
        end
        # end of are there associated communities
        break if pages_to_return.length == options[:limit]
      end
      # end of article loop
      pages_to_return
    end
    # end of cache block
  end
    
  
  def self.main_lessons_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tag].nil?)
      self.articles.bucketed_as('learning lessons').ordered.limit(options[:limit]).all 
    else
      self.articles.bucketed_as('learning lessons').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
    end
   end
  end
      
  def self.contents_for_content_tag(options = {})
    self.articles.bucketed_as('contents').tagged_with_content_tag(options[:content_tag].name).ordered.first
  end
  
  def self.parse_id_from_atom_entryid(idurl,source)
    begin
      parsedurl = URI.parse(idurl)
    rescue
      return nil
    end
    
    case source
    when 'copwiki'
    else
      if(idlist = parsedurl.path.scan(/\d+/))
        id = idlist[0]
        return id
      else
        return nil
      end
    end

  end
     
  def self.create_or_update_from_atom_entry(entry,page_source)
    current_time = Time.now.utc
    # copwiki atom id's include a revision number, so we have to use
    # the link rel='alternate' which should be the only link
    # as the source url
    if(page_source.name == 'copwiki')
      provided_source_url = entry.links[0].href
    else
      provided_source_url = entry.id
    end
    
    page = self.find_by_source_url(provided_source_url) || self.new
    page.source = page_source.name
    page.page_source = page_source
    # set or reset broken links flag
    page.has_broken_links = false
    
    # updated
    page.source_updated_at = (entry.updated.nil? ? current_time : entry.updated)
    # published (set to updated if no published and updated available)
    if(entry.published.nil?)
      if(entry.updated.nil?)
        page.source_created_at = current_time
      else
        page.source_created_at = entry.updated
      end
    else
      page.source_created_at = entry.published
    end
    
    # category processing
    entry_category_terms = []
    if(!entry.categories.blank?)
      entry_category_terms = entry.categories.map(&:term)
    end

    # check for delete
    if(!entry_category_terms.blank? and entry_category_terms.include?('delete'))
      returndata = [page.source_updated_at, 'deleted', page.source_url]
      page.destroy
      return returndata
    end
    
    # check for 'animal manure management' or 'ag energy' from the copwiki
      # so that we can ignore dpl content and duplicate data
      if(page_source.name == 'copwiki')
        if(!entry_category_terms.blank? and (entry_category_terms.include?('animal manure management') or entry_category_terms.include?('ag energy')))
          returndata = [page.source_updated_at, 'ignored', provided_source_url]
          return returndata
        end
      end
      
      
    # check for datatype
    if(!entry_category_terms.blank?)
      # news overrides article => overrides faq
      if(entry_category_terms.include?('news') or entry_category_terms.include?('originalnews') )
        page.datatype = 'News'
      elsif(entry_category_terms.include?('article'))
        page.datatype = 'Article'
      elsif(entry_category_terms.include?('faq'))
        page.datatype = 'Faq'
      else
        page.datatype = page_source.default_datatype
      end
    else
      page.datatype = page_source.default_datatype
    end
    
    # flag as dpl
    if(!entry_category_terms.blank? and entry_category_terms.include?('dpl'))
      page.is_dpl = true
    end
      
    # set noindex if news
    if(page.datatype == 'News' and !entry_category_terms.include?('originalnews'))
      page.indexed = Page::NOT_INDEXED
    end
    
    # set noindex if noindex
    if(entry_category_terms.include?('noindex'))
      page.indexed = Page::NOT_INDEXED
    end
    
    # set noindex if noindex
    if(entry_category_terms.include?('nogoogleindex'))
      page.indexed = Page::NOT_GOOGLE_INDEXED
    end
    
    # set indexed if forceindex present
    if(entry_category_terms.include?('forceindex'))
      page.indexed = Page::INDEXED
    end
    
      
    page.source_id = entry.id
    if(page.source_url.blank?)
      page.source_url = provided_source_url 
      page.source_url_fingerprint = Digest::SHA1.hexdigest(provided_source_url.downcase)
    end
    
    if(page.datatype == 'Event')
      event_data = hCalendar.find(:first => {:text => entry.content.to_s})
      page.title = event_data.summary
      page.original_content = CGI.unescapeHTML(event_data.description)
      page.event_start = event_data.dtstart

      if event_data.properties.include?("dtend")
        duration = (event_data.dtend - event_data.dtstart) / (24 * 60 * 60) # result in days
        page.event_duration = duration.to_i
      end

      location = event_data.location.split('|')
      page.event_location = location[0]
      page.coverage = location[1]
      page.state_abbreviations = location[2]

      if event_data.properties.include?('status')
        if event_data.status == 'CANCELLED'
          returndata = [page.source_updated_at, 'deleted', page.source_url]
          page.destroy
          return returndata
        end
      end
    else
      page.title = entry.title
      page.original_content = entry.content.to_s
    end

    # reference_pages
    reference_pages_array = []
    if(!entry.links.blank?)
      reference_pages_array = []
      entry.links.each do |link|
        if(link.rel == 'related')
          reference_pages_array << link.href
        end
      end
      page.reference_pages = reference_pages_array.join(',')
    end
    
    # process timezone
    if (!entry.categories.blank?)
      if(tz_category = entry.categories.detect{|category| category.label == "time_zone"})
        page.time_zone = tz_category.term
        # remove timezone category so other categories can be parsed out as tags
        # entry.categories.delete(tz_category) is not working for this, so explicitly find the category
        entry.categories.delete_if{|category| category.label == "time_zone"}
      
        # reset entry_category_terms if we deleted a time zone
        entry_category_terms = []
        if(!entry.categories.blank?)
          entry_category_terms = entry.categories.map(&:term)
        end
      end
    end
    

    if(page.new_record?)
      returndata = [page.source_updated_at, 'added']
      page.save
    elsif(page.original_content_changed?)
      returndata = [page.source_updated_at, 'updated']
      page.save
    else
      # content didn't change, don't save the article - most useful for dpl's
      returndata = [page.source_updated_at, 'nochange']
    end
  

    # handle categories - which will include updating categories/tags
    # even if the content didn't change
    if(!entry_category_terms.blank?)
      page.replace_tags_with_and_cache(entry_category_terms,User.systemuserid,Tagging::CONTENT)
      page.put_in_buckets(entry_category_terms)    
    
      # check for homage replacement    
      if(entry_category_terms.include?('homage'))
        content_tags = page.tags.content_tags
        content_tags.each do |content_tag|
          if(community = content_tag.content_community)
            community.update_attribute(:homage_id,page.id)
          end
        end
      end
    
    end
    
    returndata << page
    return returndata
  end
  
  def set_url_title
    self.url_title = self.make_url_title
  end
  
  # override
  def url_title
    if(my_url_title = read_attribute(:url_title))
      my_url_title
    else
      make_url_title
    end
  end
  
  def make_url_title
    # make an initial downcased copy - don't want to modify name as a side effect
    tmp_url_title = self.title.downcase
    # get rid of anything that's not a "word", not whitespace, not : and not - 
    tmp_url_title.gsub!(/[^\s0-9a-zA-Z:-]/,'')
    # reduce whitespace/multiple spaces to a single space
    tmp_url_title.gsub!(/\s+/,' ')
    # remove leading and trailing whitespace
    tmp_url_title.strip!
    # convert spaces and underscores to dashes
    tmp_url_title.gsub!(/[ _]/,'-')
    # reduce multiple dashes to a single dash
    tmp_url_title.gsub!(/-+/,'-')
    # truncate
    tmp_url_title.truncate(URL_TITLE_LENGTH,{:omission => '', :avoid_orphans => true})
  end
  
  
  def id_and_link(only_path = false, params = {})
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
      default_url_options[:port] = default_port
    end
    page_params = {:id => self.id, :title => self.url_title, :only_path => only_path}
    if(params)
      page_params.merge!(params)
    end
    page_url(page_params) 
  end
  
  # called by Link#href_url to return an href to this article
  def href_url
    self.id_and_link(true)
  end
  
  def to_atom_entry
    Atom::Entry.new do |e|
      e.title = Atom::Content::Html.new(self.title)
      e.links << Atom::Link.new(:type => "text/html", :rel => "alternate", :href => self.id_and_link)
      e.authors << Atom::Person.new(:name => 'Contributors')
      e.id = self.id_and_link
      e.updated = self.source_updated_at
      e.categories = self.cached_content_tag_names.map{|name| Atom::Category.new({:term => name, :scheme => url_for(:controller => 'main', :action => 'index')})}
      e.content = Atom::Content::Html.new(self.content)
    end
  end
  
  def self.find_by_legacy_title_from_url(url)
   return nil unless url
   real_title = url.gsub(/_/, ' ')
   self.where("created_at <= '2011-03-21'").where("datatype IN ('Article','News')").find_by_title(real_title)
  end
  
  def self.find_by_title_url(url)
   return nil unless url
   real_title = url.gsub(/_/, ' ')
   self.find_by_title(real_title)
  end
  
  def self.find_by_alt_reference(providedreference)
    # dup reference
    reference = providedreference.dup
    # dump any print param
    if reference =~ /\/print(\/)?$/
      reference.gsub!(/\/print(\/)?$/, '')
    end
    
    if(reference =~ %r{/pages/(\d+)})
      # is this a /pages/id reference?
      self.find_by_id($1)
    elsif(reference =~ %r{/faq/(\d+)})
      # is this a /faq/id reference?
      self.faqs.find_by_source_id($1)
    elsif(reference =~ %r{/events/(\d+)})
      # is this an /events/id reference?
      self.events.find_by_source_id($1)
    elsif(reference =~ %r{/article/(\d+)})
      # is this an /article/id reference?
      self.articles.find_by_id($1)
    elsif(reference =~ %r{/pages/(.+)})
      # is this a /pages/Title reference?  
      self.find_by_title_url($1) 
    elsif(reference =~ %r{/wiki/(.+)})
      # is this a /wiki/Title reference? (no idea how, but we get them)
      self.find_by_title_url($1) 
    else
      nil
    end
  end


  def source_host
    # make sure the URL is valid format
    begin
      source_uri = URI.parse(self.source_url)
    rescue
      return nil
    end
    return source_uri.host
  end
  
  def convert_links
    returninfo = {:invalid => 0, :wanted => 0, :ignored => 0, :internal => 0, :external => 0, :mailto => 0, :category => 0, :directfile => 0, :local => 0}
    # walk through the anchor tags and pull out the links
    converted_content = Nokogiri::HTML::DocumentFragment.parse(original_content)
    
    # images first
    
    if(self.is_copwiki_or_create?)
      convert_image_count = 0
      # if we are running in the "production" app location - then we need to rewrite image references that
      # refer to the host of the feed to reference a relative URL
      converted_content.css('img').each do |image|
        if(image['src'])
          begin
            original_uri = URI.parse(image['src'])
          rescue
            image.set_attribute('src', '')
            next
          end
          
          if(image_link = Link.find_or_create_by_image_reference(original_uri.to_s,self.source_host))
            image.set_attribute('src', image_link.href_url)
            if(!self.links.include?(image_link))
              self.links << image_link
            end
          else
            image.set_attribute('src', '')
          end            
          convert_image_count += 1
        end # img tag had a src attribute
      end # loop through the img tags
      returninfo.merge!({:images => convert_image_count})
    end
      
    converted_content.css('a').each do |anchor|
      if(anchor['href'])
        if(anchor['href'] =~ /^\#/) # in-page anchor, don't change      
          next
        end
        
        # make sure the URL is valid format
        begin
          original_uri = URI.parse(anchor['href'])
        rescue
          anchor.set_attribute('href', '')
          next
        end
        
        # find/create a Link for this link
        link = Link.find_or_create_by_linked_url(original_uri.to_s,self.source_host)
        if(link.blank?)
          # pull out the children from the anchor and place them
          # up next to the anchor, and then remove the anchor
          anchor.children.reverse.each do |child_node|
           anchor.add_next_sibling(child_node)
          end
          anchor.remove
          if(link.nil?)
            returninfo[:invalid] += 1
          else
            returninfo[:ignored] += 1
          end
        else
          if(!self.links.include?(link))
            self.links << link
          end
          case link.linktype
          when Link::WANTED
            # pull out the children from the anchor and place them
            # up next to the anchor, and then remove the anchor
            anchor.children.reverse.each do |child_node|
             anchor.add_next_sibling(child_node)
            end
            anchor.remove
            returninfo[:wanted] += 1
          when Link::INTERNAL
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'internal_link')
            returninfo[:internal] += 1
          when Link::LOCAL
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'local_link')
            returninfo[:local] += 1
          when Link::EXTERNAL
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'external_link')
            returninfo[:external] += 1
          when Link::MAILTO
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'mailto_link')
            returninfo[:mailto] += 1
          when Link::CATEGORY
            newhref = link.href_url
            # ignore the fragment
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'category_link')
            returninfo[:category] += 1
          when Link::DIRECTFILE
            newhref = link.href_url
            # ignore the fragment
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'file_link')
            returninfo[:directfile] += 1
          when Link::IMAGE
            newhref = link.href_url
            # ignore the fragment
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'file_link')
            returninfo[:directfile] += 1
          end
        end
      end
    end
    

    
    self.content = converted_content.to_html
    returninfo
  end
    
  def store_new_url
    self.url = id_and_link
    self.save
  end
  
  def create_primary_link
    Link.create_from_page(self)
  end
  
  def change_primary_link
    # update items that might link to this article
    if(!self.primary_link.blank?)
      self.primary_link.change_to_wanted
    end
  end
  
  def check_content
   if self.original_content_changed?
    self.reprocess_links # sets self.content
    self.set_sizes
   end
  end
  
  def store_content #ac    
    self.convert_links # sets self.content
    self.set_sizes
    self.save    
  end
  
  # Reprocesses the links in the given article by deleting the existing linkings 
  # for the article and running convert_links again to parse the links in the article
  # 
  # @param [Boolean] save save self after processing (default: true)
  # @return [Hash] output from convert_links with the counts of the various link types in the article
  def reprocess_links
    self.linkings.destroy_all
    result = self.convert_links
    result
  end
  
  # override of standard reference_questions getter, that will sanity check reference questions list.
  # returns an array of valid reference questions
  def reference_pages
    returnarray = []
    if(reflist = read_attribute(:reference_pages))
      refpage_url_array = reflist.split(',')
      refpage_fingerprints = refpage_url_array.map{|url| "'#{Digest::SHA1.hexdigest(url)}'"}
      if(!refpage_fingerprints.blank?)
        returnarray = Page.all(:conditions => "source_url_fingerprint IN (#{refpage_fingerprints.join(',')})")
      end
    end
    if(returnarray.blank?)
      return nil
    else
      return returnarray    
    end
  end
  
  def self.content_cache_expiry
    if(!AppConfig.configtable['cache-expiry'][self.name].nil?)
      AppConfig.configtable['cache-expiry'][self.name]
    else
      15.minutes
    end
  end
  
  def has_map?
    (!event_location.blank?) and !(event_location.downcase.match(/web based|http|www|\.com|online/))
  end
  
  def local_to?(state)
    (state_abbreviations.include?(state) or (event_location and event_location.include?(state)))
  end
    
  def states
    clean_abbreviations.collect { | abbrev | Location.find_by_abbreviation(abbrev).name }
  end

  def state_names
    states.join(', ')
  end

  def state_abbreviations=(new_value)
    write_attribute(:state_abbreviations,self.clean_abbreviations(new_value).join(' '))
  end

  def sort_states
    self.state_abbreviations = clean_abbreviations.sort.join(' ')
  end
  
  # override timezone writer/reader
  # use convert=false when you need a timezone string that mysql can handle
  def time_zone(convert=true)
    tzinfo_time_zone_string = read_attribute(:time_zone)

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
    reverse_mappings = ActiveSupport::TimeZone::MAPPING.invert
    if(mappings[time_zone_string])
      write_attribute(:time_zone, mappings[time_zone_string])
    elsif(reverse_mappings[time_zone_string])
      write_attribute(:time_zone, time_zone_string)
    else
      write_attribute(:time_zone, nil)
    end
  end

  def clean_abbreviations(abbreviations_string = self.state_abbreviations)
    return [] unless abbreviations_string
    abbreviations_string.split(/ |;|,/).compact.delete_if { | each | each.blank? }.collect { | each | each.upcase }.uniq
  end
    
  def content_to_s
    nokogiri_doc = Nokogiri::HTML::DocumentFragment.parse(self.content)
    nokogiri_doc.css('script').each { |node| node.remove }
    nokogiri_doc.css('link').each { |node| node.remove }
    nokogiri_doc.text.squeeze(" ").squeeze("\n")
  end
  
  def set_sizes
    (self.content_length,self.content_words) = self.content_sizes
  end
    
  def content_sizes
    text = self.content_to_s
    [text.size,text.scan(/[\w-]+/).size]
  end
  
  def event_date
    @event_date || (self.event_start.blank? ? nil : (self.event_all_day? ? self.event_start.utc.to_date : self.event_start.in_time_zone(self.time_zone).to_date))
  end
  
  def event_time
    @event_time || (self.event_start.blank? ? nil : (self.event_all_day? ? nil : self.event_start.in_time_zone(self.time_zone).strftime('%I:%M %p')))
  end
  
  def event_duration
    read_attribute(:event_duration) || (self.event_all_day? ? 1 : 0)
  end
  
  def displaytitle
    self.title.truncate(255,{:omission => '', :avoid_orphans => true})
  end
  
  def self.find_by_source_name_and_id(source_name,source_id)
    page_source = PageSource.find_by_name(source_name)
    return nil if(page_source.blank?)
    Page.find_by_source_url(page_source.page_source_url(source_id))
  end
    

end
