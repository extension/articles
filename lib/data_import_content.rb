# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'timeout'
require 'open-uri'
require 'rexml/document'
require 'net/http'

module DataImportContent
  
  # returns a block of content read from a file or a URL, does not parse
  def fetch_url_content(feed_url)
    urlcontent = ''
    # figure out if this is a file url or a regular url and behave accordingly
    fetch_uri = URI.parse(feed_url)
    if(fetch_uri.scheme.nil?)
      raise ContentRetrievalError, "Fetch URL Content:  Invalid URL: #{feed_url}"
    elsif(fetch_uri.scheme == 'file')
      if File.exists?(fetch_uri.path)
        File.open(loadfromfile) { |f|  urlcontent = f.read }          
      else
        raise ContentRetrievalError, "Fetch URL Content:  Invalid file #{fetch_uri.path}"        
      end
    elsif(fetch_uri.scheme == 'http' or fetch_uri.scheme == 'https')  
      # TODO: need to set If-Modified-Since
      http = Net::HTTP.new(fetch_uri.host, fetch_uri.port) 
      http.read_timeout = 300
      response = fetch_uri.query.nil? ? http.get(fetch_uri.path) : http.get(fetch_uri.path + "?" + fetch_uri.query)
      case response
      # TODO: handle redirection?
      when Net::HTTPSuccess
        urlcontent = response.body
      else
        raise ContentRetrievalError, "Fetch URL Content:  Fetch from #{parse_url} failed: #{response.code}/#{response.message}"          
      end    
    else # unsupported URL scheme
      raise ContentRetrievalError, "Fetch URL Content:  Unsupported scheme #{feed_url}"          
    end
    
    return urlcontent
  end
  
  
  def build_feed_url(feed_url,refresh_since,xmlschematime=true)
    fetch_uri = URI.parse(feed_url)
    if(fetch_uri.scheme.nil?)
      raise ContentRetrievalError, "Build Feed URL:  Invalid URL: #{feed_url}"
    elsif(refresh_since.nil?)
      return "#{feed_url}"
    elsif(fetch_uri.scheme == 'file')
      return "#{feed_url}"
    else
      if(xmlschematime)
        return "#{feed_url}#{refresh_since.xmlschema}"
      else
        return "#{feed_url}/#{refresh_since.year}/#{refresh_since.month}/#{refresh_since.day}/#{refresh_since.hour}/#{refresh_since.min}/#{refresh_since.sec}"
      end
    end
  end
  
  
  def retrieve_content(options = {})
     current_time = Time.now.utc
     refresh_all = (options[:refresh_all].nil? ? false : options[:refresh_all])
     refresh_without_time = (options[:refresh_without_time].nil? ? false : options[:refresh_without_time])
     update_retrieve_time = (options[:update_retrieve_time].nil? ? true : options[:update_retrieve_time])
     
     case self.name
     when 'Event'
       feed_url = (options[:feed_url].nil? ? AppConfig.configtable['content_feed_events'] : options[:feed_url])
       usexmlschematime = false
     when 'Faq'
       feed_url = (options[:feed_url].nil? ? AppConfig.configtable['content_feed_faqs'] : options[:feed_url])
       usexmlschematime = false
     when 'Article'
       feed_url = (options[:feed_url].nil? ? AppConfig.configtable['content_feed_wikiarticles'] : options[:feed_url])
       usexmlschematime = true
     when 'ExternalArticle'
       if(options[:feed_url].nil?)
         raise ContentRetrievalError, "Retrieve Content:  Retrieval External sources must supply a valid url for the external source"
       end
       feed_url =  options[:feed_url]
       usexmlschematime = true
     else
       raise ContentRetrievalError, "Retrieve Content: Unknown object type for content retrieval (#{self.name})"
     end  
    
     if(update_retrieve_time)
       updatetime = UpdateTime.find_or_create(self,'content')
     end
     
     if(refresh_without_time)
       # build URL without a time
       refresh_since = AppConfig.configtable['epoch_time'] # so we have a date for comparisons below
       fetch_url = self.build_feed_url(feed_url,nil)
     elsif(refresh_all)
       refresh_since = (options[:refresh_since].nil? ? AppConfig.configtable['content_feed_refresh_since'] : options[:refresh_since])
       fetch_url = self.build_feed_url(feed_url,refresh_since,usexmlschematime)
     elsif(update_retrieve_time)
       refresh_since = (updatetime.last_datasourced_at.nil? ? AppConfig.configtable['content_feed_refresh_since'] : updatetime.last_datasourced_at)           
       fetch_url = self.build_feed_url(feed_url,refresh_since,usexmlschematime)
     else
       raise ContentRetrievalError, "Retrieve Content: Invalid options. (no knowledge of what last update time to use).  (#{self.name} objects from #{feed_url})."
     end
    
    # will raise errors on failure
    xmlcontent = self.fetch_url_content(fetch_url)

    # create new objects from the atom entries
    added_items = 0
    updated_items = 0
    deleted_items = 0
    last_updated_item_time = refresh_since
    

    atom_entries =  Atom::Feed.load_feed(xmlcontent).entries
    if(!atom_entries.blank?)
      atom_entries.each do |entry|
        (object_update_time, object_op, object) = self.create_or_update_from_atom_entry(entry)
        # get smart about the last updated time
        if(object_update_time > last_updated_item_time )
          last_updated_item_time = object_update_time
        end
      
        case object_op
        when 'deleted'
          deleted_items += 1
        when 'updated'
          updated_items += 1
        when 'added'
          added_items += 1
        end
      end
    
      if(update_retrieve_time)
        # update the last retrieval time, add one second so we aren't constantly getting the last record over and over again
        updatetime.update_attribute(:last_datasourced_at,last_updated_item_time + 1)
      end
    end
    
    return {:added => added_items, :deleted => deleted_items, :updated => updated_items, :last_updated_item_time => last_updated_item_time}
  end

end