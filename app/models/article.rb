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
  after_create :store_new_url
  before_update :check_content
  
  has_content_tags
  ordered_by :orderings => {'Newest to oldest'=> 'wiki_updated_at DESC'},
         :default => "#{self.table_name}.wiki_updated_at DESC"
         
  named_scope :bucketed_as, lambda{|bucketname|
   {:include => :content_buckets, :conditions => "content_buckets.name = '#{ContentBucket.normalizename(bucketname)}'"}
  }
   
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
      article.replace_tags(entry.categories.map(&:term),User.systemuserid,Tag::CONTENT)
      article.put_in_buckets(entry.categories.map(&:term))    
    end

    returndata << article
    return returndata
  end
  
  def id_and_link
   default_url_options[:host] = AppConfig.get_url_host
   default_url_options[:protocol] = AppConfig.get_url_protocol
   if(default_port = AppConfig.get_url_port)
    default_url_options[:port] = default_port
   end
   
   if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
    article_page_url(:id => self.id)
   else
    wiki_page_url(:title => self.title_url)
   end
  
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
  
  # Resolve the links in this article's body and save the article
  def resolve_links!    
   self.resolve_links
   self.save
  end
  
  # Make sure incoming links that point to relative urls
  # are either made absolute if the content the point
  # to doesn't exist in pubsite or are made to point to
  # pubsite content if it has been imported.
  def resolve_links
   # Pull out each link
   self.content = self.original_content.gsub(/href="(.+?)"/) do
    
    # Pull match from regex cruft
    link_uri = $1
    full_uri = $&
    
    # Only if it's not already an extension.org url nor a fragment do
    # we want to try and resolve it
    if not (link_uri.extension_url? or link_uri.fragment_only_url?)
      begin
       # Calculate the absolute path to the original location of this link
       uri = link_uri.relative_url? ?
        URI.parse(self.original_url).swap_path!(link_uri) :
        URI.parse(link_uri)
       
       # See if we've imported the original article.
       new_link_uri = (existing_article = Article.find(:first, :select => 'url', :conditions => { :original_url => uri.to_s })) ?
        existing_article.url : nil
       
       if new_link_uri
        # found published article, replace link
        result = "href=\"#{new_link_uri}\""
       elsif link_uri.relative_url?
        # link was relative and no published article found
        result = "name=\"not-published-#{uri.to_s}\""
       else
        # appears to be an ext. ref, just pass it
        result = "href=\"#{uri.to_s}\""
       end
      rescue
       result = full_uri
      end #rescue block
    else
      result = full_uri
    end #if
        
    result
   end #do
  end
  
  # 
  # converts relative hrefs and hrefs that refer to the feed source
  # to something relative to /pages - this conversion doesn't bother
  # to look ahead and see if the target article is published
  # because WikiAtomizer was already responsible for handling that
  #
  # TODO: revisit doing a lookahead for wiki articles too.
  #
  def convert_wiki_links_and_images
    if(self.original_content.blank?)
      return [0,0]
    end
    if(@converted_content.nil?)
      @converted_content = Nokogiri::HTML::DocumentFragment.parse(self.original_content)
    end

    wikisource_uri = URI.parse(AppConfig.configtable['content_feed_wikiarticles'])
    host_to_make_relative = wikisource_uri.host

    convert_links_count = 0
    @converted_content.css('a').each do |anchor|
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

        if(original_uri.scheme.nil?)
          # does path start with '/wiki'? - then strip it out
          if(original_uri.path =~ /^\/wiki\/(.*)/) # does path start with '/wiki'? - then strip it out
            newhref =  '/pages/' + $1
          elsif(original_uri.path =~ /^\/mediawiki\/(.*)/) # does path start with '/mediawiki'? hmmmm = linking directly to a file I think, leave as is.
            newhref = original_uri.path
          else
            newhref =  '/pages/'+ original_uri.path
          end
          anchor.set_attribute('href',newhref)
          convert_links_count += 1
        elsif((original_uri.scheme == 'http' or original_uri.scheme == 'https') and original_uri.host == host_to_make_relative)
          if(original_uri.path =~ /^\/wiki\/(.*)/) # does path start with '/wiki'? - then strip it out
            newhref =  '/pages/' + $1
          elsif(original_uri.path =~ /^\/mediawiki\/(.*)/) # does path start with '/mediawiki'? hmmmm = linking directly to a file I think, leave as is, relative to me - will fail at www.demo
            newhref = original_uri.path
          else
            newhref =  '/pages/'+ original_uri.path
          end
          # attach the fragment and the query to the end of it if there was one
          if(!original_uri.fragment.blank?)
            newhref += "##{original_uri.fragment}"
          end
          if(!original_uri.query.blank?)
            newhref += "?#{original_uri.query}"
          end
          anchor.set_attribute('href',newhref)
          convert_links_count += 1   
        end # scheme was http/https and what we needed to make relative
      end # did this anchor have an href attribute?
    end # loop through all the anchor tags
   
    convert_image_count = 0
    # if we are running in the "production" app location - then we need to rewrite image references that
    # refer to the host of the feed to reference a relative URL
    if(AppConfig.configtable['app_location'] == 'production')
      @converted_content.css('img').each do |image|
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
            # attach the fragment and the query to the end of it if there was one
            if(!original_uri.fragment.blank?)
              newsrc += "##{original_uri.fragment}"
            end
            if(!original_uri.query.blank?)
              newsrc += "?#{original_uri.query}"
            end
            image.set_attribute('src',newsrc)
            convert_image_count += 1
          end
        end # img tag had a src attribute
      end # loop through the img tags
    end # was this the production site?

    self.content = @converted_content.to_html
    return [convert_links_count,convert_image_count]
  end
  
  private
   
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
  
  def check_content
   if self.original_content_changed?
    if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
      self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
      self.content = nil
    elsif(self.datatype == 'WikiArticle')
      self.convert_wiki_links_and_images # sets self.content
    else
      self.content = self.original_content
    end
   end
  end
  
  def store_content #ac
   if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
    self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
   elsif(self.datatype == 'WikiArticle')
    self.convert_wiki_links_and_images # sets self.content
   end
   self.save    
  end
  
end
