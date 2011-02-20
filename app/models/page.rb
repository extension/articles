# === COPYRIGHT:
# Copyright (c) 2005-2011 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
class Page < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  include TaggingScopes
  
  extend DataImportContent   # utility functions for importing content

  URL_TITLE_LENGTH = 100
  
  # currently, no need to cache, we don't fulltext search article tags
  # has_many :cached_tags, :as => :tagcacheable
  
   
  before_create :store_source_url
  after_create :store_content
  after_create :set_url_title, :create_primary_content_link
  before_update :check_content
  before_destroy :change_primary_content_link
  
  has_content_tags
  ordered_by :orderings => {'Newest to oldest'=> "source_updated_at DESC"},
                            :default => "source_updated_at DESC"
         
  has_one :primary_content_link, :class_name => "ContentLink", :as => :content  # this is the link for this article
  has_many :linkings
  has_many :content_links, :through => :linkings
  has_many :bucketings
  has_many :content_buckets, :through => :bucketings
  has_one :content_link_stat

  named_scope :bucketed_as, lambda{|bucketname|
   {:include => :content_buckets, :conditions => "content_buckets.name = '#{ContentBucket.normalizename(bucketname)}'"}
  }
  
  named_scope :broken_links, :conditions => {:has_broken_links => true}

  named_scope :articles, :conditions => {:datatype => 'Article'}
  named_scope :news, :conditions => {:datatype => 'News'}
  named_scope :faqs, :conditions => {:datatype => 'Faq'}
  named_scope :events, :conditions => {:datatype => 'Event'}
  named_scape :newsicles, :conditions => ["(datatype = 'Article' OR datatype = 'News')"]
  
  named_scope :by_datatype, lambda{|datatype|
   if(datatype.is_a?(Array))
     datatypes_list = datatype.map{|d| "'#{d}'"}.join(',')
     {:conditions => "datatype IN (#{datatypes_list})"}
   else
     {:conditions => "datatype = '#{datatype}'"}
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
  
  
  # returns the number of links associated with this page, if updated_at > the content_link_stat for this page
  # it counts and updates the content_link_stat
  #
  # @return [Hash] keyed hash of the link counts for this page
  def content_link_counts
    linkcounts = {:total => 0, :external => 0,:local => 0, :wanted => 0, :internal => 0, :broken => 0, :redirected => 0, :warning => 0}
    if(self.content_link_stat.nil? or self.updated_at > self.content_link_stat.updated_at)      
      self.content_links.each do |cl|
        linkcounts[:total] += 1
        case cl.linktype
        when ContentLink::EXTERNAL
          linkcounts[:external] += 1
        when ContentLink::INTERNAL
          linkcounts[:internal] += 1
        when ContentLink::LOCAL
          linkcounts[:local] += 1
        when ContentLink::WANTED
          linkcounts[:wanted] += 1
        end
      
        case cl.status
        when ContentLink::BROKEN
          linkcounts[:broken] += 1
        when ContentLink::OK_REDIRECT
          linkcounts[:redirected] += 1
        when ContentLink::WARNING
          linkcounts[:warning] += 1
        end
      end
      if(self.content_link_stat.nil?)
        self.create_content_link_stat(linkcounts)
      else
        self.content_link_stat.update_attributes(linkcounts)
      end
    else
      linkcounts.keys.each do |key|
        linkcounts[key] = self.content_link_stat.send(key)
      end
    end
    return linkcounts
  end
  
  # mass update of the has_broken_links flag, looping through them all if needed is waaaaaay too slow
  def self.update_broken_flags
    # set all to false
    update_all("has_broken_links = 0")
    
    # get a list that have more than one broken link
    broken_list = count('content_links.id',:joins => :content_links,:conditions => "content_links.status IN (#{ContentLink::WARNING},#{ContentLink::BROKEN}) ",:group => "#{self.table_name}.id")
    broken_ids = broken_list.keys
    update_all("has_broken_links = 1", "id IN (#{broken_ids.join(',')})")    
  end

  # update broken flag for this page 
  def update_broken_flag
    broken_count = self.content_links.count(:conditions => "content_links.status IN (#{ContentLink::WARNING},#{ContentLink::BROKEN}) ")
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
  
  
  # return an array of the content tag names for this page, filtering out the blacklist
  # returns it from memcache or from an association call to the db
  # 
  # @return [Array] array of content tag names 
  # @param [Boolean] forcecacheupdate force caching update  
  def content_tag_names(forcecacheupdate = false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.class.get_cache_key(this_method,{})
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.class.content_cache_expiry) do
     self.tags.content_tags.reject{|t| Tag::CONTENTBLACKLIST.include?(t.name) }.compact.map{|t| t.name}
   end
  end
  

  # return a collection of the most recent news articles for the specified limit/content tag
  # will check memcache first
  # 
  # @return [Array<Page>] array/collection of matching pages
  # @param [Hash] options query options
  # @option options [Integer] :limit query limit
  # @option opts [ContentTag] :content_tag ContentTag to search for
  # @param [Boolean] forcecacheupdate force caching update
  def self.main_news_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tag].nil?)
      self.news.ordered.limit(options[:limit]).find(:all)
    else
      self.news.tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).find(:all)
    end
   end
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
      articles_to_return = []
      
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
        community_ids = self.community_ids_string.split(',')
        
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
  
  def self.main_recent_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tags].nil? or options[:content_tags].empty?)
      self.by_datatype(['Article','News']).ordered.limit(options[:limit]).all 
    else
      if options[:tag_operator] and options[:tag_operator] == 'and'
        self.by_datatype(['Article','News']).tagged_with_all(options[:content_tags]).ordered.limit(options[:limit]).all
      else
        self.by_datatype(['Article','News']).tagged_with_any_content_tags(options[:content_tags]).ordered.limit(options[:limit]).all
      end
    end
   end
  end
  
  def self.main_recent_faq_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tags].nil? or options[:content_tags].empty?)
      self.faqs.ordered.limit(options[:limit]).all 
    else
      if options[:tag_operator] and options[:tag_operator] == 'and'
        self.faqs.tagged_with_all(options[:content_tags]).ordered.limit(options[:limit]).all
      else
        self.faqs.tagged_with_any_content_tags(options[:content_tags]).ordered.limit(options[:limit]).all
      end
    end
   end
  end
  
  def self.main_recent_event_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tags].nil? or options[:content_tags].empty?)
      self.events.ordered.limit(options[:limit]).all 
    else
      if options[:tag_operator] and options[:tag_operator] == 'and'
        self.events.tagged_with_all(options[:content_tags]).ordered.limit(options[:limit]).all
      else
        self.events.tagged_with_any_content_tags(options[:content_tags]).ordered.limit(options[:limit]).all
      end
    end
   end
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
      
  def self.contents_for_content_tag(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    self.articles.bucketed_as('contents').tagged_with_content_tag(options[:content_tag].name).ordered.first
   end
  end
   
  def self.create_or_update_from_atom_entry(entry,datatype = 'WikiArticle')
    if(datatype == 'WikiArticle')
      article = find_by_title(entry.title) || self.new
    else
      article = find_by_source_url(entry.links[0].href) || self.new
    end

    self.datatype = datatype

    if entry.updated.nil?
      updated = Time.now.utc
    else
      updated = entry.updated
    end
    self.source_updated_at = updated

    if entry.published.nil?
      pubdate = updated
    else
      pubdate = entry.published
    end
    self.wiki_created_at = pubdate

    if !entry.categories.blank? and entry.categories.map(&:term).include?('delete')
      returndata = [self.source_updated_at, 'deleted', nil]
      self.destroy
      return returndata
    end

    self.title = entry.title
    self.url = entry.links[0].href if self.url.blank?
    self.author = entry.authors[0].name
    self.original_content = entry.content.to_s

    # flag as dpl
    if !entry.categories.blank? and entry.categories.map(&:term).include?('dpl')
      self.is_dpl = true
    end
 
    if(self.new_record?)
      returndata = [self.source_updated_at, 'added']
      self.save
    elsif(self.original_content_changed?)
      returndata = [self.source_updated_at, 'updated']
      self.save
    else
      # content didn't change, don't save the article - most useful for dpl's
      returndata = [self.source_updated_at, 'nochange']
    end

    # handle categories - which will include updating categories/tags
    # even if the content didn't change
    if(!entry.categories.blank?)
      self.replace_tags(entry.categories.map(&:term),User.systemuserid,Tagging::CONTENT)
      self.put_in_buckets(entry.categories.map(&:term))    
    end
    
    # check for homage replacement    
    if(entry.categories.map(&:term).include?('homage'))
      content_tags = self.tags.content_tags
      content_tags.each do |content_tag|
        if(community = content_tag.content_community)
          community.update_attribute(:homage_id,self.id)
        end
      end
    end
    returndata << article
    return returndata
  end
  
  def set_url_title
    self.update_attribute(:url_title,get_url_title)
  end
  
  def get_url_title
    # make an initial downcased copy - don't want to modify name as a side effect
    tmp_url_title = self.title.downcase
    # get rid of anything that's not a "word", not whitespace, not : and not - 
    tmp_url_title.gsub!(/[^\w\s:-]/,'')
    # reduce whitespace/multiple spaces to a single space
    tmp_url_title.gsub!(/\s+/,' ')
    # convert spaces and underscores to dashes
    tmp_url_title.gsub!(/[ _]/,'-')
    # remove leading and trailing whitespace
    tmp_url_title.strip!
    # truncate
    tmp_url_title.truncate(URL_TITLE_LENGTH,{:omission => '', :avoid_orphans => true})
  end
  
  
  def id_and_link(only_path = false)
    if(self.url_title.blank?)
      self.set_url_title
    end
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
    default_url_options[:port] = default_port
    end
    page_url(:id => self.id, :title => self.url_title, :only_path => only_path)
  end
  
  # called by ContentLink#href_url to return an href to this article
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
      e.categories = self.content_tag_names.map{|name| Atom::Category.new({:term => name, :scheme => url_for(:controller => 'main', :action => 'index')})}
      e.content = Atom::Content::Html.new(self.content)
    end
  end
  
  def self.find_by_title_url(url)
   return nil unless url
   real_title = url.gsub(/_/, ' ')
   self.find_by_title(real_title)
  end

  def published_at
   source_updated_at
  end
  
  def representative_field
   if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
    'id'
   else
    'title'
   end
  end
  
  def page
   if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
    'article'
   else
    'wiki'
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
    converted_content = Nokogiri::HTML::DocumentFragment.parse(self.original_content)
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
        
        # find/create a ContentLink for this link
        link = ContentLink.find_or_create_by_linked_url(original_uri.to_s,self.source_host)
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
          if(!self.content_links.include?(link))
            self.content_links << link
          end
          case link.linktype
          when ContentLink::WANTED
            # pull out the children from the anchor and place them
            # up next to the anchor, and then remove the anchor
            anchor.children.reverse.each do |child_node|
             anchor.add_next_sibling(child_node)
            end
            anchor.remove
            returninfo[:wanted] += 1
          when ContentLink::INTERNAL
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'internal_link')
            returninfo[:internal] += 1
          when ContentLink::LOCAL
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'local_link')
            returninfo[:local] += 1
          when ContentLink::EXTERNAL
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'external_link')
            returninfo[:external] += 1
          when ContentLink::MAILTO
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'mailto_link')
            returninfo[:mailto] += 1
          when ContentLink::CATEGORY
            newhref = link.href_url
            # ignore the fragment
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'category_link')
            returninfo[:category] += 1
          when ContentLink::DIRECTFILE
            newhref = link.href_url
            # ignore the fragment
            anchor.set_attribute('href', newhref)
            anchor.set_attribute('class', 'file_link')
            returninfo[:directfile] += 1
          end
        end
      end
    end
    
    if(self.datatype == 'WikiArticle')    
      wikisource_uri = URI.parse(AppConfig.configtable['content_feed_wikiarticles'])
      host_to_make_relative = wikisource_uri.host
      convert_image_count = 0
      # if we are running in the "production" app location - then we need to rewrite image references that
      # refer to the host of the feed to reference a relative URL
      if(AppConfig.configtable['app_location'] == 'production')
        converted_content.css('img').each do |image|
          if(image['src'])
            begin
              original_uri = URI.parse(image['src'])
            rescue
              image.set_attribute('src', '')
              next
            end

            if((original_uri.scheme == 'http' or original_uri.scheme == 'https') and original_uri.host == host_to_make_relative)
              # make relative
              newsrc = original_uri.path
              image.set_attribute('src',newsrc)
              convert_image_count += 1
            end
          end # img tag had a src attribute
        end # loop through the img tags
      end # was this the production site?
      returninfo.merge!({:images => convert_image_count})
    end
    
    self.content = converted_content.to_html
    returninfo
  end
    
  def store_new_url
   if(!self.datatype.nil? and (self.datatype == 'ExternalArticle' or self.datatype == 'WikiArticle'))
    self.url = id_and_link
    self.save
   else
    return true
   end
  end
  
  def create_primary_content_link
    ContentLink.create_from_content(self)
  end
  
  def change_primary_content_link
    # update items that might link to this article
    if(!self.primary_content_link.nil?)
      self.primary_content_link.change_to_wanted
    end
  end
  
  def check_content
   if self.original_content_changed?
    if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
      self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
    end
    self.reprocess_links(false) # sets self.content
   end
  end
  
  def store_content #ac    
    if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
      self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
    end
    self.convert_links # sets self.content
    self.save    
  end
  
  # Reprocesses the links in the given article by deleting the existing linkings 
  # for the article and running convert_links again to parse the links in the article
  # 
  # @param [Boolean] save save self after processing (default: true)
  # @return [Hash] output from convert_links with the counts of the various link types in the article
  def reprocess_links(save = true)
    self.linkings.destroy_all
    result = self.convert_links
    if(save)
      self.save
    end
    result
  end
  
  # override of standard reference_questions getter, that will sanity check reference questions list.
  # returns an array of valid reference questions
  def reference_pages
    returnarray = []
    if(reflist = read_attribute(:reference_pages))
      refpage_id_array = reflist.split(',')
      refpage_id_array.each do |refpage|
        if(page = Page.find_by_source_id(refpage))
          returnarray << page
        end
      end
    end
    if(returnarray.blank?)
      return nil
    else
      return returnarray    
    end
  end
  
end
