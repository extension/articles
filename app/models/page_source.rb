# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
require 'timeout'
require 'open-uri'
require 'net/http'

class PageSource < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  serialize :last_requested_information
  serialize :default_request_options
  has_many :pages
  
  named_scope :active, :conditions => {:active => true}
  
  def page_feed_url(source_id,options = {})
    if(!options[:demofeed].blank?)
      use_demo_uri = options[:demofeed]
    elsif(AppConfig.configtable['sourcefilter'] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name]['demofeed'])
      use_demo_uri = AppConfig.configtable['sourcefilter'][self.name]['demofeed']
    else
      use_demo_uri = false
    end
    
    # check config for override for dev mode
    if(AppConfig.configtable['sourcefilter'] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name]['page_uri'])
      feed_url = AppConfig.configtable['sourcefilter'][self.name]['page_uri']
    elsif(use_demo_uri)
      if(self.demo_uri.blank?)
        feed_url = 'error://no-demo-uri-for-this-source'  # will fail parsing as invalid URI
      else
        feed_url = self.demo_page_uri
      end
    else
      feed_url = self.page_uri
    end
    
    format(feed_url,CGI::escape(source_id.to_s))
  end
      
  def feed_url(options = {})
    if(!options[:demofeed].blank?)
      use_demo_uri = options[:demofeed]
    elsif(AppConfig.configtable['sourcefilter'] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name]['demofeed'])
      use_demo_uri = AppConfig.configtable['sourcefilter'][self.name]['demofeed']
    else
      use_demo_uri = false
    end
    
    request_options = self.default_request_options
    if(options[:request_options])
      if(request_options.blank?)
        request_options = options[:request_options]
      else
        request_options.merge!(options[:request_options])
      end
    end
    
    if(self.retrieve_with_time)
      if(options[:refresh_since] and options[:refresh_since] != 'default')
        updated_time = options[:refresh_since]
      elsif(self.latest_source_time)
        updated_time = self.latest_source_time
      else
        updated_time = AppConfig.configtable['epoch_time']
      end
      
      if(request_options.blank?)
        request_options = {'updated-min' => updated_time.xmlschema}
      else
        request_options.merge!({'updated-min' => updated_time.xmlschema})
      end
    end
    
    # check config for override for dev mode
    if(AppConfig.configtable['sourcefilter'] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name] and AppConfig.configtable['sourcefilter'][self.name]['uri'])
      feed_url = AppConfig.configtable['sourcefilter'][self.name]['uri']
    elsif(use_demo_uri)
      if(self.demo_uri.blank?)
        feed_url = 'error://no-demo-uri-for-this-source'  # will fail parsing as invalid URI
      else
        feed_url = self.demo_uri
      end
    else
      feed_url = self.uri
    end
    
    if(!request_options.blank?)
      feed_url += '?' + request_options.map{|key,value| "#{key}=#{value}"}.join('&')
    end
    return feed_url
  end
  
  def atom_feed(options = {})
    if(@atom_feed.blank?)
      @atom_feed = self.class.atom_feed(self.feed_url(options))
    end
    
    @atom_feed
  end
  
  def atom_entries(options = {})
    self.atom_feed(options).entries
  end
  
  def atom_page_feed(source_id,options={})
    @atom_page_feed = self.class.atom_feed(self.page_feed_url(source_id,options))
  end
  
  def atom_page_entry(source_id,options={})
    self.atom_page_feed(source_id,options).entries[0]
  end
  
  def retrieve_content(options = {})
    update_retrieve_time = (options[:update_retrieve_time].nil? ? true : options[:update_retrieve_time])
    begin
      atom_entries = self.atom_entries(options)
    rescue Exception => e
      self.update_attributes({:last_requested_at => Time.now.utc, :last_requested_success => false, :last_requested_information => {:errormessage => e.message}})
      return nil
    end
    

    # create new objects from the atom entries
    item_counts = {:adds => 0, :deletes => 0, :errors => 0, :updates => 0, :nochange => 0}
    item_ids = {:adds => [], :deletes => [], :errors => [], :updates => [], :nochange => []}
    last_updated_item_time = self.latest_source_time  

    if(!atom_entries.blank?)
      atom_entries.each do |entry|
        begin
          (object_update_time, object_op, object) = Page.create_or_update_from_atom_entry(entry,self)
          
          # get smart about the last updated time
          if(last_updated_item_time.nil?)
            last_updated_item_time = object_update_time
          elsif(object_update_time > last_updated_item_time )
            last_updated_item_time = object_update_time
          end
          
          case object_op
          when 'deleted'
            item_counts[:deletes] += 1
            # for deletes "object" is actually the source_url for the page
            item_ids[:deletes] << object
          when 'updated'
            item_counts[:updates] += 1
            item_ids[:updates] << object.id
          when 'added'
            item_counts[:adds] += 1
            item_ids[:adds] << object.id
          when 'error'
            item_counts[:errors] += 1
            # for errors "object" is actually an error message for the page
            # or it will be if we ever return errors from create_or_update_from_atom_entry
            item_ids[:errors] << object
          when 'nochange'
            item_counts[:nochange] += 1
            item_ids[:nochange] << object.id
          end
        rescue Exception => e
          item_counts[:errors] += 1
          if(entry.id)
            message = "#{entry.id}:#{e.message}"
          else
            message = e.message
          end
          item_ids[:errors] << message
        end # exception handling for create_or_update_from_atom_entry
      end
    
      update_options = {:last_requested_at => Time.now.utc, :last_requested_success => true, :last_requested_information => {:item_counts => item_counts, :item_ids => item_ids}}
      
      if(update_retrieve_time)
        # update the last retrieval time, add one second so we aren't constantly getting the last record over and over again
        update_options.merge!({:latest_source_time => last_updated_item_time + 1})     
      end
    else
      update_options = {:last_requested_at => Time.now.utc, :last_requested_success => true, :last_requested_information => {:note => 'Empty feed'}}
    end
    
    self.update_attributes(update_options)
    return {:item_counts => item_counts, :item_ids => item_ids, :last_updated_item_time => last_updated_item_time}
  end
  
  
  def self.atom_feed(fetch_url)
    xmlcontent = self.fetch_url_content(fetch_url)
    Atom::Feed.load_feed(xmlcontent)
  end
    
  # returns a block of content read from a file or a URL, does not parse
  def self.fetch_url_content(fetch_url)
    urlcontent = ''
    # figure out if this is a file url or a regular url and behave accordingly
    fetch_uri = URI.parse(fetch_url)
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
        raise ContentRetrievalError, "Fetch URL Content:  Fetch from #{fetch_url} failed: #{response.code}/#{response.message}"          
      end    
    else # unsupported URL scheme
      raise ContentRetrievalError, "Fetch URL Content:  Unsupported scheme #{fetch_url}"          
    end
    
    return urlcontent
  end
end