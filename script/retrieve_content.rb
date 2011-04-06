#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'lockfile'


class RetrieveContent < Thor
  include Thor::Actions
  
  # these are not the tasks that you seek
  no_tasks do
    # load rails based on environment
    
    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
    end
    
    def get_refresh_since(options)
      if(options[:refresh_since])
        case options[:refresh_since]
        when 'default'
          'default'
        when 'lastday'
          Time.now.utc - 1.day
        when 'lastweek'
          Time.now.utc - 1.week
        when 'lastmonth'
          Time.now.utc - 1.month
        else
          begin
            Time.parse(refresh_since)
          rescue
            'default'
          end
        end
      else
        'default'
      end
    end              
  
    
    def get_page_sources(options)
      if(options[:sources] == 'all')
        PageSource.all(:order => 'name')
      elsif(options[:sources] == 'active')
        PageSource.active.all(:order => 'name')
      else
        sourcelist = options[:sources].split(/\s*,\s*/)
        sources_string = sourcelist.map{|source| "'#{source.strip}'"}.join(',')
        PageSource.all(:conditions => "name IN (#{sources_string})",:order => 'name')
      end
    end
  end


  desc "sources", "show available sources (and whether active or inactive)"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def sources
    load_rails(options[:environment])
    source_options = {}
    source_options[:refresh_since] = get_refresh_since(options)
    puts PageSource.all(:order => 'name').map{|source| "#{source.name} (#{source.active? ? 'active' : 'inactive'})"}.join("\n")
  end
  
  desc "sourceinfo", "show sources and information"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :refresh_since,:default => 'default', :aliases => "-t", :desc => "Refresh since provided time (parseable time or 'lastday','lastweek','lastmonth','default')"
  method_option :sources,:default => 'active', :aliases => "-s", :desc => "Comma delimited list of sources to request (run the 'sources' command to show available sources).  Also 'active' or 'all'."
  method_option :last,:default => 'false', :aliases => "-l", :desc => "Show last request result"

  def sourceinfo
    load_rails(options[:environment])
    source_options = {}
    source_options[:refresh_since] = get_refresh_since(options)
    sources = get_page_sources(options)
    sources.each do |page_source|
      puts "\n'#{page_source.name}'"
      puts "Latest source time at last update: #{page_source.latest_source_time.strftime("%B %e, %Y, %l:%M %p %Z")}"
      puts "Source url: #{page_source.feed_url(source_options)}"
      puts "Active: #{(page_source.active? ? 'true' : 'false')}"
      if(options[:last])
        if(page_source.last_requested_at)
          puts "Last updated: #{page_source.last_requested_at.strftime("%B %e, %Y, %l:%M %p %Z")}"
          puts "Last request result: #{page_source.last_requested_success? ? 'success' : 'failure'}"
          puts "Last request information: #{page_source.last_requested_information.inspect}"        
        else
          puts "No last request information"
        end
      end
    end
  end
  
  desc "request", "request available content and show the number of atom entries available (does not update)"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :refresh_since,:default => 'default', :aliases => "-t", :desc => "Refresh since provided time (parseable time or 'lastday','lastweek','lastmonth','default')"
  method_option :sources,:default => 'active', :aliases => "-s", :desc => "Comma delimited list of sources to request (run the 'sources' command to show available sources).  Also 'active' or 'all'."
  def request
    load_rails(options[:environment])
    source_options = {}
    source_options[:refresh_since] = get_refresh_since(options)
    sources = get_page_sources(options)
    sources.each do |page_source|
      puts "\n'#{page_source.name}'"
      puts "Source url: #{page_source.feed_url(source_options)}"
      atom_entries = page_source.atom_entries(source_options)
      puts "Atom Entry count: #{atom_entries.size}"
    end
  end
  
  desc "update", "request available content and add/update/delete pages as appropriate"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :refresh_since,:default => 'default', :aliases => "-t", :desc => "Refresh since provided time (parseable time or 'lastday','lastweek','lastmonth','default')"
  method_option :sources,:default => 'active', :aliases => "-s", :desc => "Comma delimited list of sources to request (run the 'sources' command to show available sources).  Also 'active' or 'all'."
  def update
    load_rails(options[:environment])
    errors = []
    lockfile = Lockfile.new('/tmp/retrieve_content.lock', :retries => 0)
    begin
      lockfile.lock do    
        source_options = {}
        source_options[:refresh_since] = get_refresh_since(options)
        sources = get_page_sources(options)
        sources.each do |page_source|
          puts "\n'#{page_source.name}'"
          puts "Source url: #{page_source.feed_url(source_options)}"
          result = page_source.retrieve_content(source_options)
          puts "Results:"
          puts "#{result.inspect}"
          if(!page_source.last_requested_success?)
            errors << page_source.name
          end
        end
      end
    rescue Lockfile::MaxTriesLockError => e
      $stderr.puts "Another content fetcher is already running. Exiting."
    end
    
    if(!errors.blank?)
      $stderr.puts "There were errors with the following page sources:  #{errors.join(',')}"
      $stderr.puts "Please run retrieve_content sourceinfo --last to get more information"
    end
  end
  
end

RetrieveContent.start
