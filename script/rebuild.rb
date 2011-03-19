#!/usr/bin/env ruby
require 'rubygems'
require 'thor'
require 'net/http'
require 'uri'


class Rebuild < Thor
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
        page.set_sizes
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
    
    def split_array(array, chunks)
      size = array.size
      splitpoint = (size/chunks)
      splits = []
      start = 0
      1.upto(chunks) do |i|
        last = start+splitpoint
        last = last-1 unless size%chunks >= i
        splits << array[start..last] || []
        start = last+1
      end
      splits
    end
    
  end


  desc "page_cached_content_tags", "Rebuild cached tags for Pages (doesn't show progress)"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Output verbose progress"
  def page_cached_content_tags
    load_rails(options[:environment])
    # this is the same as CachedTag.rebuild_all - but looping here to show progress
    Page.all.each do |page|
      cached_tag = CachedTag.create_or_update(page,User.systemuserid,Tagging::CONTENT)
      puts "Processed Page #{page.id} : #{cached_tag.fulltextlist}" if (options[:verbose])
    end
  end

  desc "total_linkcounts", "show total link counts"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def total_linkcounts
    load_rails(options[:environment])
    puts "Total link count #{Link.count}"
    puts "Link counts by type:"
    linkcounts = Link.count_by_linktype
    linkcounts.each do |linktype,count|
      puts "\t#{linktype} => #{count}"
    end
  end
  
  desc "touch_pages", "Touch pages will rebuild url titles"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Output verbose progress"
  def touch_pages
    load_rails(options[:environment])
    Page.all.each do |page|
      page.touch # set_url_title runs before save
      puts "Processed Page #{page.id} #{page.url_title}" if (options[:verbose])
    end
  end
  
  desc "link_stats", "Rebuild link stats"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :verbose,:default => true, :aliases => "-v", :desc => "Output verbose progress"
  def link_stats
    load_rails(options[:environment])
    Page.all.each do |page|
      counts = page.link_counts(true)
      puts "Processed Page #{page.id} #{counts.inspect}" if (options[:verbose])
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
  
  desc "sitemaps", "Recreate sitemaps"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def sitemaps
    load_rails(options[:environment])
    # get the pages
    @pages = Page.indexed
    index_pages_count = (@pages.size / 50000) + 1

    # create the index
    File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_index.xml", 'w') do |sitemap_index|
      sitemap_index.puts('<?xml version="1.0" encoding="UTF-8"?>')
      sitemap_index.puts('<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
      # communities
      sitemap_index.puts('<sitemap>')
      sitemap_index.puts('<loc>http://www.extension.org/sitemaps/sitemap_communities.xml</loc>')
      sitemap_index.puts('</sitemap>')
      # pages
      if(index_pages_count == 1)
        sitemap_index.puts('<sitemap>')
        sitemap_index.puts('<loc>http://www.extension.org/sitemaps/sitemap_pages.xml</loc>')
        sitemap_index.puts('</sitemap>')
      else
        for i in (1..index_pages_count)
          sitemap_index.puts('<sitemap>')
          sitemap_index.puts("<loc>http://www.extension.org/sitemaps/sitemap_pages_#{i}.xml</loc>")
          sitemap_index.puts('</sitemap>')
        end
      end
      sitemap_index.puts('</sitemapindex>')
    end

    # communities
    File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_communities.xml", 'w') do |sitemap_communities|
      sitemap_communities.puts('<?xml version="1.0" encoding="UTF-8"?>')
      sitemap_communities.puts('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
      Community.launched.each do |community|
        community.cached_content_tags.each do |name|
          sitemap_communities.puts('<url>')
          sitemap_communities.puts("<loc>http://www.extension.org/#{URI.encode(name)}</loc>")
          sitemap_communities.puts('</url>')
        end
      end
      sitemap_communities.puts('</urlset>')
    end

    # pages
    if(index_pages_count == 1)
      File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_pages.xml", 'w') do |sitemap_pages|
        sitemap_pages.puts('<?xml version="1.0" encoding="UTF-8"?>')
        sitemap_pages.puts('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
        @pages.each do |page|
          sitemap_pages.puts('<url>')
          sitemap_pages.puts("<loc>http://www.extension.org/pages/#{page.id}/#{page.url_title}</loc>")
          sitemap_pages.puts("<lastmod>#{page.source_updated_at.xmlschema}</loc>")      
          sitemap_pages.puts('</url>')
        end
        sitemap_pages.puts('</urlset>')
      end
    else
      splits = split_array(@pages,index_pages_count)
      for i in (1..index_pages_count)
        File.open("#{RAILS_ROOT}/public/sitemaps/sitemap_pages_#{i}.xml", 'w') do |sitemap_pages|
          sitemap_pages.puts('<?xml version="1.0" encoding="UTF-8"?>')
          sitemap_pages.puts('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
          splits[i-1].each do |page|
            sitemap_pages.puts('<url>')
            sitemap_pages.puts("<loc>http://www.extension.org/pages/#{page.id}/#{page.url_title}</loc>")
            sitemap_pages.puts("<lastmod>#{page.source_updated_at.xmlschema}</loc>")      
            sitemap_pages.puts('</url>')
          end
          sitemap_pages.puts('</urlset>')
        end
      end
    end  
  end
  
  
  
  
end

Rebuild.start
