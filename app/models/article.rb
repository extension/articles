# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
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
  before_update :check_content
  
  has_content_tags
  ordered_by :orderings => {'Newest to oldest'=> 'wiki_updated_at DESC'},
             :default => "#{self.table_name}.wiki_updated_at DESC"
             
  has_many :article_buckets
  has_many :content_buckets, :through => :article_buckets
  
  named_scope :bucketed_as, lambda{|bucketname|
    {:include => :content_buckets, :conditions => "content_buckets.name = '#{ContentBucket.normalizename(bucketname)}'"}
  }
  
  def put_in_buckets(categoryarray)
    logger.info "categoryarray = #{categoryarray.inspect}"
    namearray = []
    categoryarray.each do |name|
      namearray << ContentBucket.normalizename(name)
    end
    
    buckets = ContentBucket.find(:all, :conditions => "name IN (#{namearray.map{|n| "'#{n}'"}.join(',')})")
    self.content_buckets = buckets
  end
  
  def self.create_or_update_from_atom_entry(entry)
    article = find_by_original_url(entry.links[0].href) || self.new
    
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
      pubdate = Time.now.utc
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
    article.original_content = entry.content
  
    if(article.new_record?)
      returndata = [article.wiki_updated_at, 'added']
    else
      returndata = [article.wiki_updated_at, 'updated']
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
     refresh_all = (options[:refresh_all].nil? ? false : options[:refresh_all])
     update_retrieve_time = (options[:update_retrieve_time].nil? ? true : options[:update_retrieve_time])
     feed_url = (options[:feed_url].nil? ? AppConfig.configtable['changes_feed_wiki'] : options[:feed_url])
     updatetime = UpdateTime.find_or_create(self,'changes')
     
     if(refresh_all)
       refresh_since = (options[:refresh_since].nil? ? AppConfig.configtable['changes_feed_refresh_since'] : options[:refresh_since])
     else
       refresh_since = updatetime.last_datasourced_at
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
    updatetime.update_attribute(:last_datasourced_at,last_updated_item_time + 1)
    return {:deleted => deleted_items, :last_updated_item_time => last_updated_item_time}
  end
  
  def id_and_link
    default_url_options[:host] = AppConfig.configtable['url_options']['host']
    default_url_options[:port] = AppConfig.get_url_port
    wiki_page_url(:title => self.title_url)
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
  
  def self.representative_field
    'title'
  end
  
  def self.page
    'wiki'
  end
  
  private
    
  def store_original_url
    self.original_url = self.url if !self.url.blank? and self.original_url.blank?
  end
  
  def check_content
    if self.original_content_changed?
      self.content = self.original_content
    end
  end
  
  def store_content #ac
    self.content = self.original_content
    self.save
  end
  
end
