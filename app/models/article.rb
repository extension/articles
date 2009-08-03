# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
class Article < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  
  extend DataImportContent  # utility functions for importing content
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
  
  named_scope :notdpl, {:conditions => {:is_dpl => false}}
  
  def put_in_buckets(categoryarray)
    logger.info "categoryarray = #{categoryarray.inspect}"
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
    # OPTIMIZE: Turn Off caching for now and see what impact it has with rails doing it itself
    # cache_key = self.get_cache_key(this_method,options)
    # Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      if(options[:content_tag].nil?)
        Article.bucketed_as('news').ordered.limit(options[:limit]).find(:all)
      else
        Article.bucketed_as('news').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).find(:all)
      end
    # end
  end
  
  def self.main_feature_list(options = {},forcecacheupdate=false)
    # OPTIMIZE: Turn Off caching for now and see what impact it has with rails doing it itself
    # cache_key = self.get_cache_key(this_method,options)
    # Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      if(options[:content_tag].nil?)
        Article.bucketed_as('feature').ordered.limit(options[:limit]).all 
      else
        Article.bucketed_as('feature').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
      end
    # end
  end
  
  def self.main_recent_list(options = {},forcecacheupdate=false)
    # OPTIMIZE: Turn Off caching for now and see what impact it has with rails doing it itself
    # cache_key = self.get_cache_key(this_method,options)
    # Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      if(options[:content_tag].nil?)
        Article.ordered.limit(options[:limit]).all 
      else
        Article.tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
      end
    # end
  end
  
  def self.main_lessons_list(options = {},forcecacheupdate=false)
    # OPTIMIZE: Turn Off caching for now and see what impact it has with rails doing it itself
    # cache_key = self.get_cache_key(this_method,options)
    # Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      if(options[:content_tag].nil?)
        Article.bucketed_as('learning lessons').ordered.limit(options[:limit]).all 
      else
        Article.bucketed_as('learning lessons').tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
      end
    # end
  end
  
  def self.homage_for_content_tag(options = {},forcecacheupdate=false)
    # OPTIMIZE: Turn Off caching for now and see what impact it has with rails doing it itself
    # cache_key = self.get_cache_key(this_method,options)
    # Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
        Article.bucketed_as('homage').tagged_with_content_tag(options[:content_tag].name).ordered.first
    # end
  end
  
  def self.contents_for_content_tag(options = {},forcecacheupdate=false)
    # OPTIMIZE: Turn Off caching for now and see what impact it has with rails doing it itself
    # cache_key = self.get_cache_key(this_method,options)
    # Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
        Article.bucketed_as('contents').tagged_with_content_tag(options[:content_tag].name).ordered.first
    # end
  end
    
  def self.create_or_update_from_atom_entry(entry,datatype = 'WikiArticle')
    article = find_by_original_url(entry.links[0].href) || self.new
    
    article.datatype = datatype
    
    if entry.updated.nil?
      updated = Time.now.utc
    else
      updated = entry.updated
    end
    
    # if article.wiki_updated_at
    #   if article.wiki_updated_at > updated
    #     # if ours is newer, skip this update
    #     return
    #   end
    # end
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
  
    if(article.new_record?)
      returndata = [article.wiki_updated_at, 'added']
    else
      returndata = [article.wiki_updated_at, 'updated']
    end 
    
    # flag as dpl
    if !entry.categories.blank? and entry.categories.map(&:term).include?('dpl')
      article.is_dpl = true
    end
     
    article.save
    if(!entry.categories.blank?)
      article.replace_tags(entry.categories.map(&:term),User.systemuserid,Tag::CONTENT)
      article.put_in_buckets(entry.categories.map(&:term))    
    end
    returndata << article
    return returndata
  end
  
  def self.retrieve_deletes(options = {})
     current_time = Time.now.utc
     have_refresh_since = (!options[:refresh_since].nil?)
     feed_url = (options[:feed_url].nil? ? AppConfig.configtable['changes_feed_wiki'] : options[:feed_url])
     updatetime = UpdateTime.find_or_create(self,'changes')


    if(have_refresh_since)
      refresh_since = options[:refresh_since]
    else
      refresh_since = (updatetime.last_datasourced_at.nil? ? AppConfig.configtable['changes_feed_refresh_since'] : updatetime.last_datasourced_at)           
    end
 
    fetch_url = self.build_feed_url(feed_url,refresh_since,true)
     
    
    # will raise errors on failure
    xmlcontent = self.fetch_url_content(fetch_url)

    # create new objects from the atom entries
    deleted_items = 0
    last_updated_item_time = refresh_since
    atom_entries =  Atom::Feed.load_feed(xmlcontent).entries
    if(!atom_entries.blank?)
      atom_entries.each do |entry|
        if entry.id == AppConfig.configtable['host_wikiarticle'] + "/wiki/Special:Log/delete"
          matches = entry.summary.match(/title=\"(.*)\"/)
          if matches
          title = matches[1]
            article = Article.find_by_title(title)
            if(!article.nil?)
              removed_time = entry.updated
              # if article is newer than delete record, then keep it
              if article.wiki_updated_at <= removed_time
                article.destroy
                deleted_items += 1
                if(removed_time > last_updated_item_time )
                  last_updated_item_time = removed_time
                end
              end 
            end
          end # matched title
        end # deleted entry check
      end # atom_entries array
    end # had atom entries
      
    # update the last retrieval time, add one second so we aren't constantly getting the last record over and over again
    updatetime.update_attributes({:last_datasourced_at => last_updated_item_time + 1,:additionaldata => {:deleted => deleted_itmes}})
    return {:deleted => deleted_items, :last_updated_item_time => last_updated_item_time}
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
      xml.updated self.wiki_updated_at.atom
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
  
  private
    
  def store_original_url
    self.original_url = self.url if !self.url.blank? and self.original_url.blank?
  end
  
  def store_new_url
    if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
      self.url = article_page_url(:id => self.id)
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
      else
        self.content = self.original_content
      end
    end
  end
  
  def store_content #ac
    if(!self.datatype.nil? and self.datatype == 'ExternalArticle')
      self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
    else
      self.content = self.original_content
    end
    self.save    
  end
  
end
