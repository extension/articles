# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
class Article < ActiveRecord::Base
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
  
  # so that we can generate URLs out of the model, not completely sure why - was marked as "pre Rails 2.1 stuff"
  include ActionController::UrlWriter
  default_url_options[:host] = AppConfig.configtable['url_options']['host']
  default_url_options[:port] = AppConfig.get_url_port

  named_scope :bucketed_as, lambda{|bucketname|
    {:include => :content_buckets, :conditions => "content_buckets.name = '#{ContentBucket.normalizename(bucketname)}'"}
  }
  
  def put_in_buckets(namelist)
    namearray = []
    namelist.split(',').each do |name|
      namearray << ContentBucket.normalizename(name)
    end
    
    buckets = ContentBucket.find(:all, :conditions => "name IN (#{namearray.map{|n| "'#{n}'"}.join(',')})")
    self.content_buckets = buckets
  end
  
  class << self
    
    def from_atom_entry(entry)
      article = find_by_original_url(entry.link) || self.new
      
      if entry.updated.nil?
        updated = Time.now.utc
      else
        updated = Time.parse(entry.updated)
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
        pubdate = Time.parse(entry.published)
      end
      article.wiki_created_at = pubdate
      
      article.taggings.each { |t| t.destroy }
      article.tag_list = []
      
      if entry.categories and entry.categories.include?('delete')
        article.destroy
        return
      end
      
      article.title = entry.title
      article.url = entry.link if article.url.blank?
      article.author = entry.author.name
      article.original_content = entry.content
    
      assign_tags(article, entry)
      article.save
      article
    end
  end

  def self.from_changes_entry(entry)
    article = nil
    if entry.id == AppConfig.configtable['host_wikiarticle'] + "/wiki/Special:Log/delete"
      matches = entry.summary.match(/title=\"(.*)\"/)
      if matches
        title = matches[1]
        article = Article.find_by_title(title) || nil
        if article
          removed_time = Time.parse(entry.updated)
          if article.wiki_updated_at > removed_time
            # if article is newer than delete record, then keep it
            article = nil
          end
        end
      end
    end

    article
  end
  
  def id_and_link
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
  
  #TODO: Change for Tags
  def self.assign_tags(article, feed_item)
    article.tag_list.add(*feed_item.categories)
  end
  
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
