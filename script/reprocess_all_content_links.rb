#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'net/http'
require 'uri'


class LinkManager < Thor
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
    
    def recreate_primary_links(verbose = false)
      # dump the links table
      Link.connection.execute('truncate table links;')      
      page_count = 1
      puts "Creating content links for each page"
      Page.all.each do |page|
        if(verbose)
          puts "Processing Page: #{page.id} ##{page_count}"
        end
        page.create_primary_link
        page_count += 1
      end
      return page_count
    end
    
    def recreate_linkings(verbose = false)
      # dump the linkings table
      Linking.connection.execute('truncate table linkings;')      
      page_count = 1
      overall_links = {}
      puts "Processing in-page links"
      Page.all.each do |page|
        if(verbose)
          puts "Processing Page: #{page.id} (#{page.datatype}) ##{page_count}"
        end
        links = page.convert_links
        page.save
        if(verbose)
          puts "Links: #{links.inspect}"
        end
        links.keys.each do |key|
          if(overall_links[key])
            overall_links[key] += links[key]
          else
            overall_links[key] = links[key]
          end
        end
        page_count += 1
      end
      overall_links[:page_count] = page_count
      return overall_links
    end
  end



  desc "counts", "show link counts"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def counts
    load_rails(options[:environment])
    puts "Total link count #{Link.count}"
    puts "Link counts by type:"
    linkcounts = Link.count_by_linktype
    linkcounts.each do |linktype,count|
      puts "\t#{linktype} => #{count}"
    end
  end
  
  desc "links", "Recreate links table (also recreates linkings)"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Output verbose progress"
  def links
    load_rails(options[:environment])
    recreate_primary_links(options[:verbose])
    recreate_linkings(options[:verbose])
  end

  desc "linkings", "Recreate linkings table"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Output verbose progress"
  def linkings
    load_rails(options[:environment])
    recreate_linkings(options[:verbose])
  end
  
end

LinkManager.start
