# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Faq < ActiveRecord::Base
  include ActionController::UrlWriter  # so that we can generate URLs out of the model
  extend DataImportContent  # utility functions for importing content
  
  # currently, no need to cache, we don't fulltext search tags
  # has_many :cached_tags, :as => :tagcacheable
    
  #--- New stuff
  has_content_tags
  ordered_by :orderings => {'Newest to oldest'=> 'heureka_published_at DESC'},
             :default => "#{quoted_table_name}.heureka_published_at DESC"
  
  has_many :expert_questions
  
  def self.get_cache_key(method_name,optionshash={})
    optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
    cache_key = "#{self.name}::#{method_name}::#{optionshashval}"
    return cache_key
  end
  
  def self.main_recent_list(options = {},forcecacheupdate=false)
    # OPTIMIZE: keep an eye on this caching
    cache_key = self.get_cache_key(this_method,options)
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.content_cache_expiry) do
      if(options[:content_tag].nil?)
        Faq.ordered.limit(options[:limit]).all 
      else
        Faq.tagged_with_content_tag(options[:content_tag].name).ordered.limit(options[:limit]).all 
      end
    end
  end
  
  # the current FAQ feed uses an URL for the id at some point, it probably should move to something like:
  # http://friendfeed.com/extensiondarmokproject/ae997214/how-to-make-good-id-in-atom-dive-into-mark
  def self.find_from_atom_feed_id(idurl)
    parsedurl = URI.parse(idurl)
    if(idlist = parsedurl.path.scan(/\d+/))
      id = idlist[0]
      return self.find_by_id(id)
    else
      return nil
    end
  end
  
  def self.create_or_update_from_atom_entry(entry,datatype = "ignored")
    faq = self.find_from_atom_feed_id(entry.id) || self.new
    
    if entry.updated.nil?
      updated_time = Time.now.utc
    else
      updated_time = entry.updated
    end    
    faq.heureka_published_at = updated_time
    
    if !entry.categories.blank? and entry.categories.map(&:term).include?('delete')
      returndata = [updated_time, 'deleted', nil]
      faq.destroy
      return returndata
    end
    
    faq.question = entry.title
    faq.answer = entry.content.to_s
  
    if(faq.new_record?)
      returndata = [faq.heureka_published_at, 'added']
    else
      returndata = [faq.heureka_published_at, 'updated']
    end  
    faq.save
    if(!entry.categories.blank?)
      faq.replace_tags(entry.categories.map(&:term),User.systemuserid,Tag::CONTENT)
    end
    returndata << faq
    return returndata
  end
  
  
  def id_and_link
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
      default_url_options[:port] = default_port
    end
    faq_page_url(:id => self.id.to_s)
  end
  
  def to_atom_entry
    xml = Builder::XmlMarkup.new(:indent => 2)
    
    xml.entry do
      xml.title(self.question, :type => 'html')
      xml.content(self.answer, :type => 'html')
      
      if self.categories
        self.categories.split(',').each do |cat|
          xml.category "term" => cat  
        end
      end
      
      xml.author { xml.name "Contributors" }
      xml.id(self.id_and_link)
      xml.link(:rel => 'alternate', :type => 'text/html', :href => self.id_and_link)
      xml.updated self.heureka_published_at.atom
    end
  end  
    
  #Stuff for use in pages
  def published_at
    heureka_published_at
  end
  
  def representative_field
    'id'
  end
  
  def page
    'faq'
  end
  
  def title
    question
  end  
    
end
