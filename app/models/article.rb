# === COPYRIGHT:
# Copyright (c) 2005-2009 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
class Article < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  
  extend DataImportContent   # utility functions for importing content
  # constants for tracking delete/updates/adds

  
  # currently, no need to cache, we don't fulltext search article tags
  # has_many :cached_tags, :as => :tagcacheable
  
   
  before_create :store_original_url
  after_create :store_content
  after_create :store_new_url, :create_primary_content_link
  before_update :check_content
  before_destroy :change_primary_content_link
  
  has_content_tags
  ordered_by :orderings => {'Newest to oldest'=> 'wiki_updated_at DESC'},
         :default => "#{self.table_name}.wiki_updated_at DESC"
         
  named_scope :bucketed_as, lambda{|bucketname|
   {:include => :content_buckets, :conditions => "content_buckets.name = '#{ContentBucket.normalizename(bucketname)}'"}
  }
  
  has_one :primary_content_link, :class_name => "ContentLink", :as => :content  # this is the link for this article
  # Note: has_many :content_links - outbound links using the has_many_polymorphs for content_links

  def put_in_buckets(categoryarray)
   namearray = []
   categoryarray.each do |name|
    namearray << ContentBucket.normalizename(name)
   end
   
   buckets = ContentBucket.find(:all, :conditions => "name IN (#{namearray.map{|n| "'#{n}'"}.join(',')})")
   self.content_buckets = buckets
  end
  
  def self.get_cache_key(method_name,optionshash={})
   optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
   cache_key = "#{self.name}::#{method_name}::#{optionshashval}"
   return cache_key
  end
  
  def self.main_news_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tag].nil?)
      Article.bucketed_as('news').ordered.limit(options[:limit]).find(:all)
    else
      Article.bucketed_as('news').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).find(:all)
    end
   end
  end
  
  def self.main_feature_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tag].nil?)
      Article.bucketed_as('feature').ordered.limit(options[:limit]).all 
    else
      Article.bucketed_as('feature').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
    end
   end
  end
  
  def self.main_recent_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tag].nil?)
      Article.ordered.limit(options[:limit]).all 
    else
      Article.tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
    end
   end
  end
  
  def self.main_lessons_list(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    if(options[:content_tag].nil?)
      Article.bucketed_as('learning lessons').ordered.limit(options[:limit]).all 
    else
      Article.bucketed_as('learning lessons').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
    end
   end
  end
  
  def self.homage_for_content_tag(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    Article.bucketed_as('homage').tagged_with_content_tag(options[:content_tag].name).ordered.first
   end
  end
  
  def self.learnmore_for_content_tag(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    Article.bucketed_as('learn more').tagged_with_content_tag(options[:content_tag].name).ordered.first
   end
  end
  
  def self.contents_for_content_tag(options = {},forcecacheupdate=false)
   # OPTIMIZE: keep an eye on this caching
   cache_key = self.get_cache_key(this_method,options)
   Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
    Article.bucketed_as('contents').tagged_with_content_tag(options[:content_tag].name).ordered.first
   end
  end
   
  def self.create_or_update_from_atom_entry(entry,datatype = 'WikiArticle')
    if(datatype == 'WikiArticle')
      article = find_by_title(entry.title) || self.new
    else
      article = find_by_original_url(entry.links[0].href) || self.new
    end

    article.datatype = datatype

    if entry.updated.nil?
      updated = Time.now.utc
    else
      updated = entry.updated
    end
    article.wiki_updated_at = updated

    if entry.published.nil?
      pubdate = updated
    else
      pubdate = entry.published
    end
    article.wiki_created_at = pubdate

    if !entry.categories.blank? and entry.categories.map(&:term).include?('delete')
      returndata = [article.wiki_updated_at, 'deleted', nil]
      article.destroy
      return returndata
    end

    article.title = entry.title
    article.url = entry.links[0].href if article.url.blank?
    article.author = entry.authors[0].name
    article.original_content = entry.content.to_s

    # flag as dpl
    if !entry.categories.blank? and entry.categories.map(&:term).include?('dpl')
      article.is_dpl = true
    end
 
    if(article.new_record?)
      returndata = [article.wiki_updated_at, 'added']
      article.save
    elsif(article.original_content_changed?)
      returndata = [article.wiki_updated_at, 'updated']
      article.save
    else
      # content didn't change, don't save the article - most useful for dpl's
      returndata = [article.wiki_updated_at, 'nochange']
    end

    # handle categories - which will include updating categories/tags
    # even if the content didn't change
    if(!entry.categories.blank?)
      article.replace_tags(entry.categories.map(&:term),User.systemuserid,Tagging::CONTENT)
      article.put_in_buckets(entry.categories.map(&:term))    
    end

    returndata << article
    return returndata
  end
  
  def id_and_link(only_path = false)
   default_url_options[:host] = AppConfig.get_url_host
   default_url_options[:protocol] = AppConfig.get_url_protocol
   if(default_port = AppConfig.get_url_port)
    default_url_options[:port] = default_port
   end
   
   if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
    article_page_url(:id => self.id, :only_path => only_path)
   else
    wiki_page_url(:title => self.title_url, :only_path => only_path)
   end
  end
  
  # called by ContentLink#href_url to return an href to this article
  def href_url
    self.id_and_link(true)
  end
  
  def to_atom_entry
   xml = Builder::XmlMarkup.new(:indent => 2)
   
   xml.entry do
    xml.title(self.title, :type => 'html')
    xml.content(self.content, :type => 'html')
    
    self.tag_list.each do |cat|
      xml.category "term" => cat  
    end
    
    xml.author { xml.name "Contributors" }
    xml.id(self.id_and_link)
    xml.link(:rel => 'alternate', :type => 'text/html', :href => self.id_and_link)
    xml.updated self.wiki_updated_at.xmlschema
   end
  end  
  
  def self.find_by_title_url(url)
   return nil unless url
   real_title = url.gsub(/_/, ' ')
   self.find_by_title(real_title)
  end

  def title_url
   unescaped = URI.unescape(self.title)
   unescaped.gsub(/\s/, '_') if unescaped
  end
  
  def published_at
   wiki_updated_at
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
      original_uri = URI.parse(self.original_url)
    rescue
      return nil
    end
    return original_uri.host
  end
  
  def convert_links
    returninfo = {:invalid => 0, :wanted => 0, :ignored => 0, :internal => 0, :external => 0, :mailto => 0, :category => 0, :directfile => 0}
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
            returninfo[:internal] += 1
          when ContentLink::EXTERNAL
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            returninfo[:external] += 1
          when ContentLink::MAILTO
            newhref = link.href_url
            # bring the fragment back if necessary
            if(!original_uri.fragment.blank?)
              newhref += "##{original_uri.fragment}"
            end
            anchor.set_attribute('href', newhref)
            returninfo[:mailto] += 1
          when ContentLink::CATEGORY
            newhref = link.href_url
            # ignore the fragment
            anchor.set_attribute('href', newhref)
            returninfo[:category] += 1
          when ContentLink::DIRECTFILE
            newhref = link.href_url
            # ignore the fragment
            anchor.set_attribute('href', newhref)
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
  

  def store_original_url
   self.original_url = self.url if !self.url.blank? and self.original_url.blank?
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
    self.convert_links # sets self.content
   end
  end
  
  def store_content #ac    
    if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
      self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
    end
    self.convert_links # sets self.content
    self.save    
  end
  
  def reprocess_links
    self.linkings.destroy_all
    result = self.convert_links
    self.save
    result
  end
  
end
