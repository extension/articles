# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class ActivityObject < ActiveRecord::Base
  extend ConditionExtensions
  extend DataImportActivityObject
  
  has_many :activities
  belongs_to :activity_application
  
  # NAMESPACE - not valid for justcode projects
  NS_DEFAULT = 0
  
  
  # entrytype
  UNKNOWN = 0
  FAQ = 1
  AAE = 2
  EVENT = 3
  ABOUTWIKI_PAGE = 4
  COPWIKI_PAGE = 5
  COLLABWIKI_PAGE = 6
  DOCSWIKI_PAGE = 7
  SYSWIKI_PAGE = 8
  # 9 and 10 were JUSTCODE related, and removed
  LISTPOST = 11
  
  WIKITYPES = [ABOUTWIKI_PAGE,COPWIKI_PAGE,COLLABWIKI_PAGE,DOCSWIKI_PAGE,SYSWIKI_PAGE]
  
  # entrytype strings
  ENTRYTYPELABELS = {
    UNKNOWN => 'unknown',
    FAQ => 'faq',
    AAE => 'aae_question',
    EVENT => 'event',
    ABOUTWIKI_PAGE => 'aboutwiki_page',
    COPWIKI_PAGE => 'copwiki_page',
    COLLABWIKI_PAGE => 'collabwiki_page',
    DOCSWIKI_PAGE => 'docswiki_page',
    SYSWIKI_PAGE => 'syswiki_page',
  }
  
  named_scope :published, {:conditions => {:status => 'published'}}
  named_scope :resolved, {:conditions => {:status => 'resolved'}}
  named_scope :rejected, {:conditions => {:status => 'rejected'}}
  named_scope :apologized, {:conditions => {:status => 'no answer'}}
  
  named_scope :copwikipages, {:conditions => {:entrytype => COPWIKI_PAGE}}
  named_scope :events, {:conditions => {:entrytype => EVENT}}
  named_scope :faq_questions, {:conditions => {:entrytype => FAQ}}
  named_scope :aae_questions, {:conditions => {:entrytype => AAE}}
  named_scope :filtered, lambda {|options| filter_conditions(options)}
    
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def build_entrytype_condition(options={})
      if(options[:entrytype])
        return "#{table_name}.entrytype = #{options[:entrytype]}"
      elsif(options[:entrytypes])
        return "#{table_name}.entrytype IN (#{options[:entrytypes].join(',')})"
      else
        return nil
      end
    end
    
    def build_status_condition(options={})
      if(options[:status])
        return "#{table_name}.status = '#{options[:status]}'"
      elsif(options[:statuses])
        return "#{table_name}.status IN (#{options[:statuses].map{|status| 'status'}.join(',')})"
      else
        return nil
      end
    end

    def filter_conditions(options={})
      if(options.nil?)
        options = {}
      end

      joins = []
      conditions = []

      conditions << build_date_condition(options)
      conditions << build_entrytype_condition(options)
      conditions << build_status_condition(options)

      return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}
    end
    
    def published_events(options = {}, forcecacheupdate=false)
      filteroptions = options.merge({:entrytype => EVENT,:status => 'published'})
      cache_key = self.get_cache_key(this_method,filteroptions)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do
        ActivityObject.filtered(filteroptions).count
      end
    end

    def published_copwikipages(options = {}, forcecacheupdate=false)
      filteroptions = options.merge({:entrytype => COPWIKI_PAGE,:status => 'published'})
      cache_key = self.get_cache_key(this_method,filteroptions)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do
        ActivityObject.filtered(filteroptions).count
      end
    end

    def published_faqs(options = {}, forcecacheupdate=false)
      filteroptions = options.merge({:entrytype => FAQ,:status => 'published'})
      cache_key = self.get_cache_key(this_method,filteroptions)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do
        ActivityObject.filtered(filteroptions).count
      end
    end

    def resolved_questions(options = {}, forcecacheupdate=false)
      filteroptions = options.merge({:entrytype => AAE, :status => 'resolved'})
      cache_key = self.get_cache_key(this_method,filteroptions)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do
        ActivityObject.filtered(filteroptions).count
      end
    end

    def rejected_questions(options = {}, forcecacheupdate=false)
      filteroptions = options.merge({:entrytype => AAE, :status => 'rejected'})
      cache_key = self.get_cache_key(this_method,filteroptions)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do
        ActivityObject.filtered(filteroptions).count
      end
    end

    def unanswered_questions(options = {}, forcecacheupdate=false)
      filteroptions = options.merge({:entrytype => AAE, :status => 'no answer'})
      cache_key = self.get_cache_key(this_method,filteroptions)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do
        ActivityObject.filtered(filteroptions).count
      end
    end

    def submitted_questions(options = {}, forcecacheupdate=false)
      filteroptions = options.merge({:entrytype => AAE})
      cache_key = self.get_cache_key(this_method,filteroptions)
      Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => self.count_cache_expiry) do
        ActivityObject.filtered(filteroptions).count
      end
    end
    
    def label_to_entrytype(string)
      return ENTRYTYPELABELS.index(string)
    end
    
    def wikiapplication_to_entrytype(wikiapplication)
      case wikiapplication.shortname
      when 'aboutwiki'
        return ABOUTWIKI_PAGE
      when 'collabwiki'
        return COLLABWIKI_PAGE
      when 'copwiki'
        return COPWIKI_PAGE
      when 'docswiki'
        return DOCSWIKI_PAGE
      when 'syswiki'
        return SYSWIKI_PAGE
      else
        return UNKNOWN
      end
    end
    
  end
  
end
